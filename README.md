# Snake


### Requirements
* DOSBox 0.74-3
* TASM

### Deployment
- clone the repo to `C:\TASM\BIN\snake`
- open dos box and type the following commands
```
mount e: c:\tasm
e:
cd bin
cycles=max
tasm /zi snake\src\snake.asm
tlink /v snake\src\snake.obj
cd snake\src
snake
```

