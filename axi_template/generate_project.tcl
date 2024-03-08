## Script name:   generate_project
## Script version:  1.0
## Author:  P.Trujillo (pablo@controlpaths.com)
## Date:    Mar24
## Description: Script for create a project and add axi_template_files

set projectDir ../project
set projectName axi_lite_test
set srdDir ./
set xdcDir ./

## Add board repository path
set_param board.repoPaths {/media/pablo/ext_ssd0/board_repository}

## Create project in ../project
create_project -force $projectDir/$projectName.xpr

## Set verilog as default language
set_property target_language Verilog [current_project]

## Set current board microzed.
set_property BOARD_PART avnet.com:microzed_7020:part0:1.3 [current_project]

## Adding verilog files
add_file [glob $srdDir/axi_ohs_comm.v]

## Open vivado for verify
start_gui

