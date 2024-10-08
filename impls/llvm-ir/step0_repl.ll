target triple = "x86_64-pc-linux-gnu"

; STDOUT
%FILE = type opaque
@stdout = external global %FILE*

@Greeting = constant [7 x i8] c"user> \00"

define i8* @READ(i8* %line) {

  ret i8* %line
}

define i8* @EVAL(i8* %line) {

  ret i8* %line
}

define i8* @PRINT(i8* %line) {

  ret i8* %line
}

define i8* @Rep(i8* %line) {

  %1 = call i8*
    @READ(i8* %line)

  %2 = call i8*
    @EVAL(i8* %1)

  %final = call i8*
    @PRINT(i8* %2)

  ret i8* %final
}

define i32 @main() {

  %stdout = load %FILE*, %FILE** @stdout

  br label %loop

loop:
  call i32
    @fputs(
      i8* getelementptr (
        [7 x i8],
        [7 x i8]* @Greeting,
        i64 0,
        i64 0
      ),
      %FILE* %stdout
  )

  %line = call i8*
    @Readline() ; This doesnt actually allocate new memory (see readline.ll)

  ; check for EOF
  %isEOF = icmp eq i8* %line, null
  br i1 %isEOF, label %EOF, label %ok

ok:
  %result = call i8*
    @Rep(i8* %line)

  call i32
    @puts(i8* %result)

  br label %loop

EOF:
  call void
    @Freeline(i8* %line)

  ret i32 0
}

declare i32 @puts(i8*)
declare i32 @fputs(i8*, %FILE*) ; no newline

declare i8*  @Readline()
declare void @Freeline(i8*)

