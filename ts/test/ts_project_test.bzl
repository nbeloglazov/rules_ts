"UnitTests for ts_project"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("//ts:defs.bzl", "ts_project")

# dir_test
def _dir_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    # assert the inputs to the tsc action are what we expect
    action_inputs = target_under_test[OutputGroupInfo]._action_inputs.to_list()
    asserts.equals(env, 3, len(action_inputs))
    asserts.true(env, action_inputs[0].path.find("/dir.ts") != -1)
    asserts.true(env, action_inputs[1].path.find("/_validate_dir_options.optionsvalid.d.ts") != -1)
    asserts.true(env, action_inputs[2].path.find("/tsconfig_dir.json") != -1)

    # sources should contain the .js output
    sources = target_under_test[JsInfo].sources.to_list()
    asserts.equals(env, 2, len(sources))
    asserts.true(env, sources[0].path.find("/dir.js") != -1)
    asserts.true(env, sources[1].path.find("/dir.js.map") != -1)

    # transitive_sources should contain the .js output
    transitive_sources = target_under_test[JsInfo].transitive_sources.to_list()
    asserts.equals(env, 2, len(transitive_sources))
    asserts.true(env, transitive_sources[0].path.find("/dir.js") != -1)
    asserts.true(env, transitive_sources[1].path.find("/dir.js.map") != -1)

    # declarations should only have the source declarations
    declarations = target_under_test[JsInfo].declarations.to_list()
    asserts.equals(env, 1, len(declarations))
    asserts.true(env, declarations[0].path.find("/dir.d.ts") != -1)

    # transitive_declarations should have the source declarations and transitive declarations
    transitive_declarations = target_under_test[JsInfo].transitive_declarations.to_list()
    asserts.equals(env, 1, len(transitive_declarations))
    asserts.true(env, transitive_declarations[0].path.find("/dir.d.ts") != -1)

    # types OutputGroupInfo should be the same as declarations
    asserts.equals(env, declarations, target_under_test[OutputGroupInfo].types.to_list())

    return analysistest.end(env)

_dir_test = analysistest.make(_dir_test_impl)

# use_dir_test
def _use_dir_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    # assert the inputs to the tsc action are what we expect;
    # the inputs should *NOT* includes the sources from any deps or transitive deps;
    # only declarations from deps should be included as action inputs.
    action_inputs = target_under_test[OutputGroupInfo]._action_inputs.to_list()
    asserts.equals(env, 4, len(action_inputs))
    asserts.true(env, action_inputs[0].path.find("/dir.d.ts") != -1)
    asserts.true(env, action_inputs[1].path.find("/use_dir.ts") != -1)
    asserts.true(env, action_inputs[2].path.find("/_validate_use_dir_options.optionsvalid.d.ts") != -1)
    asserts.true(env, action_inputs[3].path.find("/tsconfig_use_dir.json") != -1)

    # sources should contain the .js output
    sources = target_under_test[JsInfo].sources.to_list()
    asserts.equals(env, 2, len(sources))
    asserts.true(env, sources[0].path.find("/use_dir.js") != -1)
    asserts.true(env, sources[1].path.find("/use_dir.js.map") != -1)

    # transitive_sources should contain the .js output
    transitive_sources = target_under_test[JsInfo].transitive_sources.to_list()
    asserts.equals(env, 4, len(transitive_sources))
    asserts.true(env, transitive_sources[0].path.find("/use_dir.js") != -1)
    asserts.true(env, transitive_sources[1].path.find("/use_dir.js.map") != -1)
    asserts.true(env, transitive_sources[2].path.find("/dir.js") != -1)
    asserts.true(env, transitive_sources[3].path.find("/dir.js.map") != -1)

    # declarations should only have the source declarations
    declarations = target_under_test[JsInfo].declarations.to_list()
    asserts.equals(env, 1, len(declarations))
    asserts.true(env, declarations[0].path.find("/use_dir.d.ts") != -1)

    # transitive_declarations should have the source declarations and transitive declarations
    transitive_declarations = target_under_test[JsInfo].transitive_declarations.to_list()
    asserts.equals(env, 2, len(transitive_declarations))
    asserts.true(env, transitive_declarations[0].path.find("/use_dir.d.ts") != -1)
    asserts.true(env, transitive_declarations[1].path.find("/dir.d.ts") != -1)

    # types OutputGroupInfo should be the same as declarations
    asserts.equals(env, declarations, target_under_test[OutputGroupInfo].types.to_list())

    return analysistest.end(env)

_use_dir_test = analysistest.make(_use_dir_test_impl)

def ts_project_test_suite(name):
    """Test suite including all tests and data

    Args:
        name: Target name of the test_suite target.
    """
    _TSCONFIG = {
        "compilerOptions": {
            "declaration": True,
            "sourceMap": True,
        },
    }

    write_file(
        name = "dir_ts",
        out = "dir.ts",
        content = ["import { dirname } from 'path'; export const dir = dirname(__filename);"],
        tags = ["manual"],
    )
    ts_project(
        name = "dir",
        srcs = ["dir.ts"],
        tsconfig = _TSCONFIG,
        tags = ["manual"],
    )
    _dir_test(
        name = "dir_test",
        target_under_test = "dir",
    )

    write_file(
        name = "use_dir_ts",
        out = "use_dir.ts",
        content = ["import { dir } from './dir'; export const another_dir = dir;"],
        tags = ["manual"],
    )
    ts_project(
        name = "use_dir",
        srcs = ["use_dir.ts"],
        deps = ["dir"],
        tsconfig = _TSCONFIG,
        tags = ["manual"],
    )
    _use_dir_test(
        name = "use_dir_test",
        target_under_test = "use_dir",
    )

    native.test_suite(
        name = name,
        tests = [
            ":dir_test",
            ":use_dir_test",
        ],
    )
