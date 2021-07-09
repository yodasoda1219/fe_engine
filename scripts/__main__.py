from scripts import SCRIPTS
import sys
if len(sys.argv) < 2:
    print("No command specified!")
    exit(1)
command_name = sys.argv[1]
args = sys.argv[2:]
try:
    exit(SCRIPTS[command_name](args or list[str]()))
except KeyError:
    print("The specified command does not exist! Tried to call: \"{}\"".format(command_name))
    exit(1)