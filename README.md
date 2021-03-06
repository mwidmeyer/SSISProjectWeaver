#SSIS Project Weaver

Welcome to the SSIS Project Weaver repository. Here you will find everything you need to either 1) extend the flexible SSIS Project Weaver T-SQL-based SSIS execution framework or 2) deploy the framework and begin using it to execute your SQL Server Integration Services 2012, 2014, and/or 2016 projects. 

##Overview
The framework is built on top of the logging mechanisms found within the SSISDB database and consists of a completely T-SQL based approach to controlling the execution of SSIS packages including the order in which they are executed and their dependencies (on other packages and custom SQL-based triggers) . It also enables the execution of any valid T-SQL command(s) at user-defined points in time throughout a "batch's" execution. In addition, SSIS Project Weaver allows for the execution of packages to be based on the outcome of any other package, regardless of what SSIS project it belongs to (a current limitation of the SSIS project deployment model). Please see the *Concepts & Definitions* page for additional details.

##What Next?
To get started we recommend that you review and install the *Prerequisites* as defined in the wiki and then continue by following the *Getting Started* page. 
