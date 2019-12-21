# Snake
A snake game written in assembly for DOS

[asd]: images/demo.jpg

### Requirements
* DOSBox 0.74-3
* TASM

### Deployment
- clone the repo to `Path_To_TASM\BIN\snake`
- open dos box and type the following commands
```
mount e: <Path_To_TASM>
e:
cd bin
cycles=max
tasm /zi snake\src\snake.asm
tlink /v snake.obj
snake
```

