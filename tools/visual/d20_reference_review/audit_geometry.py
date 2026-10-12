#!/usr/bin/env python3
"""Independently inspect GLB data, face directions and gold/body visibility."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import struct

import numpy as np
from PIL import Image


class Asset:
    def __init__(self, path):
        self.path = Path(path)
        data = self.path.read_bytes()
        magic, version, total = struct.unpack_from("<III", data)
        assert magic == 0x46546C67 and version == 2 and total == len(data)
        size, tag = struct.unpack_from("<II", data, 12)
        assert tag == 0x4E4F534A
        self.document = json.loads(data[20:20 + size])
        bin_size, bin_tag = struct.unpack_from("<II", data, 20 + size)
        assert bin_tag == 0x004E4942
        self.binary = data[28 + size:28 + size + bin_size]
        self.sha256 = hashlib.sha256(data).hexdigest()
        self.nodes = self.document["nodes"]
        self.parents = {child: i for i, node in enumerate(self.nodes) for child in node.get("children", [])}

    def accessor(self, index):
        a = self.document["accessors"][index]
        v = self.document["bufferViews"][a["bufferView"]]
        width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
        dtype = np.dtype({5126: np.float32, 5123: np.uint16, 5125: np.uint32}[a["componentType"]])
        return np.ndarray((a["count"], width), dtype=dtype, buffer=self.binary, offset=v.get("byteOffset", 0) + a.get("byteOffset", 0), strides=(v.get("byteStride", width * dtype.itemsize), dtype.itemsize)).astype(float)

    def world_matrix(self, index):
        n = self.nodes[index]
        if "matrix" in n:
            m = np.array(n["matrix"]).reshape(4, 4, order="F")
        else:
            x, y, z, w = n.get("rotation", [0, 0, 0, 1])
            r = np.array([[1 - 2 * (y*y + z*z), 2*(x*y - z*w), 2*(x*z + y*w)], [2*(x*y + z*w), 1 - 2*(x*x + z*z), 2*(y*z - x*w)], [2*(x*z - y*w), 2*(y*z + x*w), 1 - 2*(x*x + y*y)]])
            m = np.eye(4)
            m[:3, :3] = r @ np.diag(n.get("scale", [1, 1, 1]))
            m[:3, 3] = n.get("translation", [0, 0, 0])
        if index in self.parents:
            m = self.world_matrix(self.parents[index]) @ m
        return m

    def mesh(self, name):
        index, node = next((i, n) for i, n in enumerate(self.nodes) if n.get("name") == name)
        primitive = self.document["meshes"][node["mesh"]]["primitives"][0]
        local = self.accessor(primitive["attributes"]["POSITION"])
        indices = self.accessor(primitive["indices"]).astype(int).ravel().reshape(-1, 3)
        matrix = self.world_matrix(index)
        world = local @ matrix[:3, :3].T + matrix[:3, 3]
        return world, local, indices, matrix

    def gold_normal(self, number):
        world, local, _, matrix = self.mesh(f"Gold_{number:02d}")
        axis = np.argmin(np.ptp(local, axis=0))
        normal = np.zeros(3)
        normal[axis] = 1
        normal = np.linalg.inv(matrix[:3, :3]).T @ normal
        normal /= np.linalg.norm(normal)
        if normal @ world.mean(axis=0) < 0:
            normal *= -1
        return normal

    def texture_pixels(self, material, field):
        m = self.document["materials"][material]
        t = m["pbrMetallicRoughness"][field] if field in ("baseColorTexture", "metallicRoughnessTexture") else m[field]
        image_index = self.document["textures"][t["index"]]["source"]
        image = self.document["images"][image_index]
        view = self.document["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        return np.asarray(Image.open(io.BytesIO(self.binary[start:start + view["byteLength"]])).convert("RGB"))

    def visibility(self):
        body, _, indices, _ = self.mesh("D20_engraved_obsidian")
        triangles = body[indices]
        v0, e1, e2 = triangles[:, 0], triangles[:, 1] - triangles[:, 0], triangles[:, 2] - triangles[:, 0]
        camera = np.array([3.8, 6.0 - 0.796, 5.0])
        result = {}
        for number in (20, 2, 8):
            world, local, indices, _ = self.mesh(f"Gold_{number:02d}")
            axis = np.argmin(np.ptp(local, axis=0))
            front = np.all(abs(local[indices, axis] - local[:, axis].max()) < 1e-6, axis=1)
            centers = world[indices[front]].mean(axis=1)
            occluded = 0
            for origin in centers:
                direction = camera - origin
                direction /= np.linalg.norm(direction)
                h = np.cross(np.broadcast_to(direction, e2.shape), e2)
                determinant = np.einsum("ij,ij->i", e1, h)
                valid = abs(determinant) > 1e-10
                f = np.divide(1, determinant, out=np.zeros_like(determinant), where=valid)
                s = origin - v0
                u = f * np.einsum("ij,ij->i", s, h)
                q = np.cross(s, e1)
                v = f * (q @ direction)
                distance = f * np.einsum("ij,ij->i", e2, q)
                hit = valid & (u >= -1e-8) & (v >= -1e-8) & (u + v <= 1 + 1e-8) & (distance > 1e-5) & (distance < 4)
                occluded += int(hit.any())
            result[str(number)] = {"sampled_front_triangle_centroids": len(centers), "body_occluded_centroids": occluded}
        return result


parser = argparse.ArgumentParser()
parser.add_argument("--candidate")
parser.add_argument("--out", default="evidence/geometry-audit.json")
args = parser.parse_args()
project = Path(__file__).resolve().parent
original = Asset(project / "d20_obsidian_gold.glb")
assert original.sha256 == "c5d971370fae51328461cbd220293d9445a14d7fd6f182b623f52551dbb8fa27"
report = {"original_sha256": original.sha256, "original_oblique_visibility": original.visibility(), "meaning": "Centroid ray samples, not percentage of glyph pixel area; static geometry review, no Jolt outcome"}
normals = [original.gold_normal(n) for n in range(1, 21)]
for n in range(1, 11):
    assert np.dot(normals[n-1], normals[20-n]) < -0.99999
report["opposite_face_pairs_sum_21"] = "PASS"
if args.candidate:
    candidate = Asset(project / args.candidate)
    old_body = original.mesh("D20_engraved_obsidian")
    new_body = candidate.mesh("D20_engraved_obsidian")
    a = np.unique(np.round(old_body[0], 5), axis=0)
    b = np.unique(np.round(new_body[0], 5), axis=0)
    assert a.shape == b.shape and np.array_equal(a, b), "Stone positions changed"
    assert len(old_body[2]) == len(new_body[2]), "Stone triangle count changed"
    for n, normal in enumerate(normals, 1):
        assert np.dot(normal, candidate.gold_normal(n)) > 0.99999, "Label direction changed"
    for field in ["baseColorTexture", "normalTexture", "occlusionTexture", "metallicRoughnessTexture"]:
        a = original.texture_pixels(0, field)
        b = candidate.texture_pixels(0, field)
        # Verify the semantic channel; unused packed channels may be repacked.
        channel = {"occlusionTexture": 0, "metallicRoughnessTexture": 1}.get(field)
        assert np.array_equal(a if channel is None else a[:, :, channel], b if channel is None else b[:, :, channel]), field + " source pixels changed"
    report.update({"candidate_sha256": candidate.sha256, "candidate_oblique_visibility": candidate.visibility(), "stone_world_positions_and_triangle_count_preserved": True, "twenty_number_face_directions_preserved": True, "albedo_normal_ao_roughness_pixels_preserved": True, "stone_triangles": len(new_body[2]), "mesh_nodes": sum("mesh" in n for n in candidate.nodes)})
path = project / args.out
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
