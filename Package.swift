// swift-tools-version:5.9
/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PackageDescription

let version = "0.6.0"
let url = "https://ossci-ios.s3.amazonaws.com/executorch/"
let debug = "_debug"
let deliverables = [
  "backend_coreml": [
    "sha256": "4e206523f1610e58b86af2bd0d3adc017f63244bb99cf6b8ed3fd87916acc18f",
    "sha256" + debug: "4956e5c01c4277049673e279a4474666ca4a6f699c95ac579790774af5397ffd",
    "frameworks": [
      "Accelerate",
      "CoreML",
    ],
    "libraries": [
      "sqlite3",
    ],
  ],
  "backend_mps": [
    "sha256": "24eecd7aa733817b3044c858bb02c564e129f7a1f0f50e98ca67f2605b6083a6",
    "sha256" + debug: "096ff35b327a5bd20befcf5293ed1947046d77f1e1548fe3cd654276652c136d",
    "frameworks": [
      "Metal",
      "MetalPerformanceShaders",
      "MetalPerformanceShadersGraph",
    ],
  ],
  "backend_xnnpack": [
    "sha256": "ca70261dd8868421a142fb25072aa67ab2c2e5c99b4649d6f2154b000eee1c93",
    "sha256" + debug: "c6f6bec2a9a74e9134dae5e1d5f920e57419ed56fc80b62431de5a5fea8e0234",
  ],
  "executorch": [
    "sha256": "2ee5eff3c1c7cc4659029ca240ba7d05738320793f38c16bcddb404525e97fe3",
    "sha256" + debug: "41163e83e35f9c67c8992b514686acd7901e0ff850cc3c8057732e790480b891",
  ],
  "kernels_custom": [
    "sha256": "73b22863be2b6c04af2cf75ba5bc7d95f6fbc353ca9710cef3b08a9cc8f9bb00",
    "sha256" + debug: "a3e079515a34e15b7067a3dae8d7d7dfcc9ea761dc7bd1f4c04ce86dce2e1e14",
  ],
  "kernels_optimized": [
    "sha256": "373616c7527a355f742590b82da83aa7950c25648e41bd85d83d4318b0f3a940",
    "sha256" + debug: "28d2ea5ee93b4ff1372ef62ee5de300062903d80cff4609c2cd2ecf59083f084",
  ],
  "kernels_portable": [
    "sha256": "9ee4ab3dbb7f50319cddc6bde83ab4035d1221c638ee65c85c42246b3d7f46f6",
    "sha256" + debug: "eca4fd6569e723bf5177f2996045a1d8b28a736bb37722164ad48d68175bcec0",
  ],
  "kernels_quantized": [
    "sha256": "c3fec02f4c8696737fe9e8e7b7d8d33e6595137ba1b90d22abe814d3af0b4f1e",
    "sha256" + debug: "bab97787380789ba1ae23a9095dd7d5a0ae2940e410d1463165792943b066b7e",
  ],
].reduce(into: [String: [String: Any]]()) {
  $0[$1.key] = $1.value
  $0[$1.key + debug] = $1.value
}
.reduce(into: [String: [String: Any]]()) {
  var newValue = $1.value
  if $1.key.hasSuffix(debug) {
    $1.value.forEach { key, value in
      if key.hasSuffix(debug) {
        newValue[String(key.dropLast(debug.count))] = value
      }
    }
  }
  $0[$1.key] = newValue.filter { key, _ in !key.hasSuffix(debug) }
}

let package = Package(
  name: "executorch",
  platforms: [
    .iOS(.v17),
    .macOS(.v10_15),
  ],
  products: deliverables.keys.map { key in
    .library(name: key, targets: ["\(key)_dependencies"])
  }.sorted { $0.name < $1.name },
  targets: deliverables.flatMap { key, value -> [Target] in
    [
      .binaryTarget(
        name: key,
        url: "\(url)\(key)-\(version).zip",
        checksum: value["sha256"] as? String ?? ""
      ),
      .target(
        name: "\(key)_dependencies",
        dependencies: [.target(name: key)],
        path: ".Package.swift/\(key)",
        linkerSettings:
          (value["frameworks"] as? [String] ?? []).map { .linkedFramework($0) } +
          (value["libraries"] as? [String] ?? []).map { .linkedLibrary($0) }
      ),
    ]
  }
)
