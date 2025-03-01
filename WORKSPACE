workspace(name = "dflat")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository", "new_git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

git_repository(
    name = "build_bazel_rules_apple",
    commit = "8562971108c11931618a220731c335e9fab9fb49",
    remote = "https://github.com/bazelbuild/rules_apple.git",
    shallow_since = "1610631418 -0600",
)

new_git_repository(
    name = "flatbuffers",
    build_file = "flatbuffers.BUILD",
    commit = "b5da526e6d44dfab9b03398af229eebbe835cc1e",
    remote = "https://github.com/google/flatbuffers.git",
    shallow_since = "1613851668 +0300",
)

new_git_repository(
    name = "swift-atomics",
    build_file = "swift-atomics.BUILD",
    commit = "ccce007d5d5462860cf0cb7839a233307424c61c",
    remote = "https://github.com/apple/swift-atomics.git",
    shallow_since = "1603395818 -0700",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

load(
    "@com_google_protobuf//:protobuf_deps.bzl",
    "protobuf_deps",
)

protobuf_deps()

http_archive(
    name = "sqlite3",
    build_file = "sqlite3.BUILD",
    sha256 = "b34f4c0c0eefad9a7e515c030c18702e477f4ef7d8ade6142bdab8011b487ac6",
    urls = ["https://www.sqlite.org/2020/sqlite-amalgamation-3330000.zip"],
)

# Optional dependencies for Apollo GraphQL support

new_git_repository(
    name = "apollo-ios",
    build_file = "apollo-ios.BUILD",
    commit = "b17ae4cef6e78d60913b33b821ff6ec32ce38c38",
    remote = "https://github.com/apollographql/apollo-ios.git",
    shallow_since = "1625073576 -0700"
)

new_git_repository(
    name = "PathKit",
    build_file = "PathKit.BUILD",
    commit = "c8f12353bca8c252713fd2e2fbc5789c39ff92f8",
    remote = "https://github.com/kylef/PathKit.git",
    shallow_since = "1581802267 +0100"
)

new_git_repository(
    name = "Stencil",
    build_file = "Stencil.BUILD",
    commit = "fd107355c20110d3707ebc2b09aed6b92f3cff7c",
    remote = "https://github.com/stencilproject/Stencil.git",
    shallow_since = "1612728587 +0100"
)

new_git_repository(
    name = "InflectorKit",
    build_file = "InflectorKit.BUILD",
    commit = "e28108ca05b3acb58990b0c05fb7ec57ba6e80bb",
    remote = "https://github.com/mattt/InflectorKit.git",
    shallow_since = "1607017920 -0800"
)

http_archive(
    name = "apollo_cli",
    build_file = "apollo_cli.BUILD",
    sha256 = "b39b2e9a6fc5296f6c39daf1a0145e4f2474077c22dc3e7a9faad638730a5c46",
    type = "tar.gz",
    urls = ["https://install.apollographql.com/legacy-cli/darwin/2.33.4"],
)

# Internal tools

new_git_repository(
    name = "SwiftArgumentParser",
    build_file = "swift-argument-parser.BUILD",
    commit = "4273ad222e6c51969e8585541f9da5187ad94e47",
    remote = "https://github.com/apple/swift-argument-parser.git",
    shallow_since = "1607637753 -0600",
)

new_git_repository(
    name = "SwiftSyntax",
    build_file = "swift-syntax.BUILD",
    commit = "d81b6a6dc2698a93dcc04304fb15a5446b5278a4",
    remote = "https://github.com/apple/swift-syntax.git",
    shallow_since = "1619981602 -0700",
)

new_git_repository(
    name = "SwiftFormat",
    build_file = "swift-format.BUILD",
    commit = "9c15831b798d767c9af0927a931de5d557004936",
    remote = "https://github.com/apple/swift-format.git",
    shallow_since = "1619649132 -0700",
)

# buildifier is written in Go and hence needs rules_go to be built.
# See https://github.com/bazelbuild/rules_go for the up to date setup instructions.

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "d1ffd055969c8f8d431e2d439813e42326961d0942bdf734d2c95dc30c369566",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.24.5/rules_go-v0.24.5.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.24.5/rules_go-v0.24.5.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

http_archive(
    name = "bazel_gazelle",
    sha256 = "b85f48fa105c4403326e9525ad2b2cc437babaa6e15a3fc0b1dbab0ab064bc7c",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.2/bazel-gazelle-v0.22.2.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.2/bazel-gazelle-v0.22.2.tar.gz",
    ],
)

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()

git_repository(
    name = "com_github_bazelbuild_buildtools",
    commit = "174cbb4ba7d15a3ad029c2e4ee4f30ea4d76edce",
    remote = "https://github.com/bazelbuild/buildtools.git",
    shallow_since = "1607975103 +0100",
)
