"""Runs solution.py against tests.json and prints one JSON result line."""
import contextlib
import copy
import importlib.util
import io
import json
import math
import sys
import traceback

MARKER = "__MIERACLE_RESULT__"
STDOUT_LIMIT = 2000


def emit(payload):
    sys.__stdout__.write(MARKER + json.dumps(payload) + "\n")


def jsonable(value):
    if isinstance(value, (list, tuple)):
        return [jsonable(v) for v in value]
    if isinstance(value, (set, frozenset)):
        return sorted((jsonable(v) for v in value), key=json.dumps)
    if isinstance(value, dict):
        return {str(k): jsonable(v) for k, v in value.items()}
    if value is None or isinstance(value, (bool, int, float, str)):
        return value
    return repr(value)


def same(actual, expected, mode):
    if mode == "float":
        if isinstance(actual, (int, float)) and isinstance(expected, (int, float)) and not isinstance(actual, bool):
            return math.isclose(actual, expected, rel_tol=1e-6, abs_tol=1e-6)
        if isinstance(actual, list) and isinstance(expected, list):
            return len(actual) == len(expected) and all(same(a, e, mode) for a, e in zip(actual, expected))
        return actual == expected
    if mode == "unordered" and isinstance(actual, list) and isinstance(expected, list):
        return sorted(actual, key=json.dumps) == sorted(expected, key=json.dumps)
    return actual == expected


def resolve(module, name):
    if hasattr(module, name):
        return getattr(module, name)
    solution = getattr(module, "Solution", None)
    if solution is not None and hasattr(solution, name):
        return getattr(solution(), name)
    raise AttributeError(f"No function named '{name}' (or Solution.{name}) was defined.")


def main():
    with open("tests.json") as f:
        config = json.load(f)
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            spec = importlib.util.spec_from_file_location("solution", "solution.py")
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
        function = resolve(module, config["functionName"])
    except BaseException as error:
        emit({"setupError": "".join(traceback.format_exception_only(type(error), error)).strip()})
        return

    results = []
    for test in config["tests"]:
        output = io.StringIO()
        try:
            with contextlib.redirect_stdout(output):
                actual = jsonable(function(*copy.deepcopy(test["args"])))
            results.append({"passed": same(actual, test["expected"], config["comparison"]), "actual": actual, "stdout": output.getvalue()[:STDOUT_LIMIT]})
        except BaseException as error:
            results.append({"passed": False, "error": "".join(traceback.format_exception_only(type(error), error)).strip(), "stdout": output.getvalue()[:STDOUT_LIMIT]})
    emit({"results": results})


main()
