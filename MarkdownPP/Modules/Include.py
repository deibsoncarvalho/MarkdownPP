# Copyright 2015 John Reese
# Licensed under the MIT license

from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

import glob
import re
import os
from os import path

from MarkdownPP.Module import Module
from MarkdownPP.Transform import Transform


class Include(Module):
    """
    Module for recursively including the contents of other files into the
    current document using a command like `!INCLUDE "path/to/filename"`.
    Target paths can be absolute or relative to the file containing the command
    """

    # matches !INCLUDE directives in .mdpp files
    includere = re.compile(r"^!INCLUDE\s+(?:\"([^\"]+)\"|'([^']+)')"
                           r"\s*(?:,\s*(\d+))?\s*$")

    # matches title lines in Markdown files
    titlere = re.compile(r"^(:?#+.*|={3,}|-{3,})$")

    # includes should happen before anything else
    priority = 0

    def transform(self, data, path):
        transforms = []

        linenum = 0
        for line in data:
            match = self.includere.search(line)
            if match:
                if path:
                    #for s in reversed(path):
                    includedata = self.include_dir(match, path)
                else:
                    includedata = self.include(match)

                transform = Transform(linenum=linenum, oper="swap",
                                    data=includedata)
                transforms.append(transform)

            linenum += 1

        return transforms

    def include_file(self, filename, pwd="", shift=0, encoding="utf-8"):
        try:
            f = open(filename, "r", encoding=encoding)
            data = f.readlines()
            f.close()

            # line by line, apply shift and recursively include file data
            linenum = 0
            for line in data:
                match = self.includere.search(line)
                if match:
                    dirname = path.dirname(filename)
                    data[linenum:linenum+1] = self.include(match, dirname)
                    # Update line so that we won't miss a shift if
                    # heading is on the 1st line.
                    line = data[linenum]

                if shift:

                    titlematch = self.titlere.search(line)
                    if titlematch:
                        to_del = []
                        for _ in range(shift):
                            if data[linenum][0] == '#':
                                data[linenum] = "#" + data[linenum]
                            elif data[linenum][0] == '=':
                                data[linenum] = data[linenum].replace("=", '-')
                            elif data[linenum][0] == '-':
                                data[linenum] = '### ' + data[linenum - 1]
                                to_del.append(linenum - 1)
                        for l in to_del:
                            del data[l]

                linenum += 1

            return data

        except (IOError, OSError) as exc:
            print(exc)

        return []

    def include(self, match, pwd=""):
        # file name is caught in group 1 if it's written with double quotes,
        # or group 2 if written with single quotes
        fileglob = match.group(1) or match.group(2)

        shift = int(match.group(3) or 0)

        result = []
        if pwd != "":
            fileglob = path.join(pwd, fileglob)

        files = sorted(glob.glob(fileglob))
        if len(files) > 0:
            for filename in files:
                result += self.include_file(filename, pwd, shift)
        else:
            print("no find file:"  ,fileglob)
            os._exit(1)
            result.append("")

        return result
    
    def include_dir(self, match, pwd):
        # file name is caught in group 1 if it's written with double quotes,
        # or group 2 if written with single quotes
        fileglob = match.group(1) or match.group(2)

        shift = int(match.group(3) or 0)

        result = []
        fileToFind = fileglob

        if -1 == fileglob.find("/"):
            for files in pwd:
                f = path.join(files, fileglob)
                if os.path.exists(f):
                    break
            fileglob = f

        files = sorted(glob.glob(fileglob))
        if len(files) > 0:
            for filename in files:
                result += self.include_file(filename, pwd, shift)
        else:
            print("no find file:", fileToFind)
            os._exit(1)
            result.append("")

        return result
