# How To

##### Full

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared
```

##### Full skip test

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared -DSKIP_CMAKE_TEST=TRUE
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared
```

##### Build

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared --target "$(basename "${PWD}")"
```

##### Build tests

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared --target test-app
```

##### Test

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared --target cmake-test
```

##### Install

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared --target cmake-install
```

##### Install skip test

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared -DSKIP_CMAKE_TEST=TRUE
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared --target cmake-install
```

##### Export

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared --target conan-export
```

##### Export skip test

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared -DSKIP_CMAKE_TEST=TRUE
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared --target conan-export
```

##### Doc

git-bash command line:
```
rm -rf build
cmake -S . --preset windows.ninja.msvc-16-x64-x64.release.shared
cmake --build --preset windows.ninja.msvc-16-x64-x64.release.shared --target cmake-doc
```

##### Remove and export all packages

git-bash command line:
```
conan remove --force "$(basename "$(pwd)")"
rm -rf build
cmake -S . --list-presets | cut -f2 -d ':' | xargs -n1 -I '{}' cmake -S . --preset '{}'
cmake -S . --list-presets | cut -f2 -d ':' | xargs -n1 -I '{}' cmake --build --preset '{}' --target conan-export
```
