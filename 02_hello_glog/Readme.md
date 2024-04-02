## Compiling

```
g++ -c main.cpp -o main.o
g++ -c main.cpp -o hello.o
```

## Compile Error

```
In file included from main.cpp:2:
hello.h:4:10: fatal error: glog/logging.h: No such file or directory
    4 | #include <glog/logging.h>
      |          ^~~~~~~~~~~~~~~~
compilation terminated.
```

## Install dependancies

```
sudo apt-get install libgoogle-glog-dev
```

## Linking

Use `-lglog` to indicate the dependence on a shared library.

```
g++ main.o hello.o -lglog -o hello
```

## Remove compile-time depandancies

```
sudo apt-get install libgoogle-glog*
```

## Runtime error

```
$ ./hello 
./hello: error while loading shared libraries: libglog.so.0: cannot open shared object file: No such file or directory
```

## Keep runtime library

```
sudo apt-get install libgoogle-glog0v5q
```
