# KvDesign

Copyright (C)  2022 LTI, ENSAJ School

KvDesign is a tool that allows to generate the key value schema from a conceptual specification of a domain.

The generic specification is defined through an instance of a *Platform Independent Data Model* (PIDM) metamodel.

This repository contains all metamodels of KvDesign's translation process, and the transformations and code generation templates that are used to transform a PIDM instance into an implementation schema in Redis system.

This tool is in a very early stage of development, so expect bugs and considerable (and probably breaking) changes of its contents.

## Structure of the *ma.kvmod.\[...\]* projects

- ***keyValueDataModel*** : Includes a metamodel for the logical description of key value family-based data stores, and code generation templates to obtain Redis schemas.
- ***pidm.lang.parent*** : Xtext language for the textual definition of PIDM instances.
- ***pidm.examples*** : Includes a project example with an instantiation of the PIDM through the defined Xtext language.
- ***pidm.transformations*** : Contains Xtend model-to-model transformations for the translation of PIDM instances into key value model.

## Required Eclipse Packages

- Xtext.
- Epsilon
- (Optional) Plantuml for Ecore packages for easy visualization.

## Installation and Usage

1. Import all projects but the examples project into Eclipse.
2. Generate model code for keyValueDataModel projects. Double click in model/(...).genmodel file and then right click ->generate model code.
3. Generate Xtext artifacts from .xtext grammar of pidm.lang/src.

You can run the Xtext editor with the LaunchRuntimePidmLang.launch run configuration on pidm.lang.parent project. On the newly opened Eclipse instance, import the pidm.examples project to see a .pidm example of an online shop.

## License

GNU General Public License version 2 or (at your option) any later version.

See LICENSE and LICENSE.gpl-2.0+ for details.
