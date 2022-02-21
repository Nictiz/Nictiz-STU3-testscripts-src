# Nictiz TestScripts NTS sources

This repository contains the NTS source files and associated materials for generating the technical test materials in the [Nictiz-STU3-testscripts repository](https://github.com/Nictiz/Nictiz-STU3-testscripts). NTS is a [custom shorthand format](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate) for generating HL7 FHIR TestScript resources.

The NTS-files and resources referenced are placed per 'project' (information standard and version) in `src/[projectname]`. NTS components that span multiple projects are placed in `src/common-components`. For more info on creating NTS projects, please see [the NTS documentation](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate). The build process sources its tooling materials from this repository (this can be overridden by passing `-Dtestscripttools.dir=/path/to/testscript/tools` to the build if needed).

The TestScripts can be generated by running the [ANT](https://ant.apache.org/) build or (on Windows) by execuiting `build-[xxx].bat` in each project directory.

The output is placed under the `dev` folder and is committed together with the sources. This folder happens to be a git subtree of the [Nictiz-STU3-testscripts](https://github.com/Nictiz/Nictiz-STU3-testscripts) repository. When the output is stable, a `git subtree push` can be performed to synchronize the final output with this repository.