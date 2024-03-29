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

## Istall dependancies

```
sudo apt-get install libgoogle-glog-dev
```

## Linking

Use `-lglog` to indicate the dependence on a shared library.

```
g++ main.o hello.o -lglog -o hello
```
