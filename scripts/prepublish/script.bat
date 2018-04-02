git.exe submodule init
git.exe submodule update
git.exe submodule foreach git pull

md android\lib\src\main\res\
robocopy %CD%\android\common\src\main\java\ %CD%\android\lib\src\main\java\ /E
robocopy %CD%\android\common\src\main\res\ %CD%\android\lib\src\main\res\ /E
