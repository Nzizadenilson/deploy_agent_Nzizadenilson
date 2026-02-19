This shell script automates the setup of a Student Attendance Tracker project. It creates the required directory structure, populates configuration files, allows updating attendance thresholds, and handles any interruptions.
Archive trigger;
If the script is interrupted by pressing Ctrl C while creating or updating the project, it will automatically:
Create an archive of the current project folder called attendance_tracker_{input}_archive.tar.gz
Delete the incomplete project folder to prevent the workspace from being messy.
