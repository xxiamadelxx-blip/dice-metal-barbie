import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from scripts.engineering_bootstrap import command, bootstrap, ollama_argv, bounded_qwen_review

class BoundedCriticTests(unittest.TestCase):
    def response(self, done=True, reason='stop', model='qwen2.5-coder:7b', reply=None):
        from unittest.mock import MagicMock
        response=MagicMock()
        response.__enter__.return_value.read.return_value=json.dumps({
            'model':model,'done':done,'done_reason':reason,
            'response':reply if reply is not None else '{"verdict":"PASS","findings":[]}',
            'eval_count':20}).encode()
        return response

    def review(self, response):
        import scripts.engineering_bootstrap as module
        from unittest.mock import MagicMock
        opener=MagicMock();opener.open.return_value=response
        with tempfile.TemporaryDirectory() as folder, \
             patch.object(module.urllib.request,'build_opener',return_value=opener):
            out=Path(folder)
            result=bounded_qwen_review('actual source excerpt','a'*40,out)
            payload=json.loads((out/'qwen-request.json').read_text())
            self.assertEqual(payload['options']['num_predict'],512)
            self.assertEqual(result['reviewed_sha'],'a'*40)
            self.assertTrue((out/'qwen-api-response.json').exists())
            return result

    def test_complete_short_structured_reply_is_evidence_not_art_acceptance(self):
        result=self.review(self.response())
        self.assertEqual(result['status'],'REVIEW_RECEIVED')
        self.assertEqual(result['findings'],'REQUIRE_TRIAGE')
        self.assertEqual(len(result['response_sha256']),64)

    def test_partial_and_token_limited_replies_never_pass(self):
        for done,reason in [(False,'stop'),(True,'length')]:
            with self.subTest(done=done,reason=reason):
                self.assertEqual(self.review(self.response(done,reason))['status'],'NOT_VERIFIED')

    def test_wrong_model_or_invalid_findings_never_pass(self):
        for response in [self.response(model='other'),self.response(reply='plain narrative'),
                         self.response(reply='{"verdict":"PASS"}')]:
            self.assertEqual(self.review(response)['status'],'NOT_VERIFIED')

    def test_transport_failure_remains_unverified(self):
        import scripts.engineering_bootstrap as module
        from unittest.mock import MagicMock
        opener=MagicMock();opener.open.side_effect=TimeoutError('deadline')
        with tempfile.TemporaryDirectory() as folder, \
             patch.object(module.urllib.request,'build_opener',return_value=opener):
            result=bounded_qwen_review('source','b'*40,Path(folder))
        self.assertEqual(result['status'],'NOT_VERIFIED')
        self.assertIn('TimeoutError',result['reason'])

class ExecutedEntryTests(unittest.TestCase):
    def test_running_prepared_container_is_used_without_host_binary(self):
        import scripts.engineering_bootstrap as module
        import subprocess
        with patch.object(module.shutil,'which',side_effect=lambda name: '/usr/bin/docker' if name=='docker' else None), \
             patch.object(module.subprocess,'run',return_value=subprocess.CompletedProcess([],0,'true\n','')) as run:
            self.assertEqual(ollama_argv(),['docker','exec','-i','dice-gauntlet-ollama','ollama'])
        self.assertEqual(run.call_args.args[0],['docker','inspect','--format','{{.State.Running}}','dice-gauntlet-ollama'])

    def test_stopped_container_never_claims_available_critic(self):
        import scripts.engineering_bootstrap as module
        import subprocess
        with patch.object(module.shutil,'which',side_effect=lambda name: '/usr/bin/docker' if name=='docker' else None), \
             patch.object(module.subprocess,'run',return_value=subprocess.CompletedProcess([],0,'false\n','')):
            self.assertIsNone(ollama_argv())

    def test_actual_failed_process_is_preserved(self):
        import sys
        with tempfile.TemporaryDirectory() as folder:
            out=Path(folder)
            result=command(out,[sys.executable,'-c','print("real evidence"); raise SystemExit(7)'],out,'failed')
            self.assertEqual(result['status'],'FAIL')
            self.assertEqual(result['exit_code'],7)
            self.assertIn('real evidence',(out/'failed.log').read_text())

    def test_missing_executable_never_passes(self):
        with tempfile.TemporaryDirectory() as folder:
            out=Path(folder)
            result=command(out,['/nonexistent/dice-tool'],out,'missing')
            self.assertEqual(result['status'],'NOT_VERIFIED')

    def test_missing_critic_and_failed_contract_block_are_explicit(self):
        import scripts.engineering_bootstrap as module
        with tempfile.TemporaryDirectory() as folder:
            out=Path(folder)
            with patch.object(module.subprocess,'check_output',return_value='a'*40), \
                 patch.object(module.shutil,'which',return_value=None), \
                 patch.object(module,'command',return_value={'status':'FAIL','exit_code':7}):
                result=bootstrap(out,out,critic=True)
            self.assertEqual(result['verdict'],'FAIL')
            self.assertEqual(result['critic']['status'],'NOT_VERIFIED')
            self.assertEqual(result['product_acceptance'],'NOT_VERIFIED')
            self.assertEqual(json.loads((out/'entry-report.json').read_text())['source_sha'],'a'*40)

if __name__=='__main__': unittest.main()
