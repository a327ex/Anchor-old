call "C:\Program Files\7-Zip\7z.exe" a -r %1.zip -w ..\ -xr!love -xr!builds -xr!steam -xr!.git
rename %1.zip %1.love
call love-js -c -m 1073741824 -t %1 %2\love\%1.love ..\builds\web
del %1.love
