import lit.formats
import os

config.name = "V6C"
config.test_format = lit.formats.ShTest(False)
config.suffixes = ['.ll', '.c']
config.test_source_root = os.path.dirname(__file__)

# Use the build dir's bin for llc and FileCheck
build_bin = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..', 'llvm-build', 'bin'))
config.environment['PATH'] = build_bin + os.pathsep + os.environ.get('PATH', '')
