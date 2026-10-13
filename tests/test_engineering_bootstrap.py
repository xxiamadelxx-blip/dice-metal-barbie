import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from scripts.engineering_bootstrap import command, bootstrap, ollama_argv

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
