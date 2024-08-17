
; NEVER do string operations on tokens
; without the size argument, otherwise
; bad things will happen.
%Token = type {
  i8*, ; lexeme
  i32  ; size
}

; stack allocate tokens
; if it's not optimal, i'll think about
; a Malloced impl.

; this array is just for allocation purposes
; the tokens in it are accessed via LL.Next/LL.Peek
@Reader.Tokens = global [80 x %Token] zeroinitializer
@Length = global i8 0

%pcre = type opaque

; \5C -> '\' and \22 -> '"'
@TOK = constant 
  [74 x i8] c"[\5Cs,]*(~@|[\5C[\5C]{}()'`~^@]|\5C\22(?:\5C\5C.|[^\5C\5C\5C\22])*\5C\22?|;.*|[^\5Cs\5C[\5C]{}('\5C\22`,;)]*)\00"

@MAX_TOKENS_ERR = constant 
  [32 x i8] c"Max number of tokens exceeded!\0A\00"

define void @Reader.Init() {

  ; TODO: @Token.Init (if dynamic memory implementation)

  call void
    @Regex.Init(
      i8* getelementptr (
        [74 x i8],
        [74 x i8]* @TOK,
        i64 0,
        i64 0
      )
  )

  call void
    @LL.Init()

  ret void
}

define void @Reader.Token(i8* %lexeme, i32 %size) {

  %len = load i8, i8* @Length
  %isFull = icmp sge i8 %len, 80

  br i1 %isFull, label %err, label %create

err:
  call void
    @Die(
      i8* getelementptr (
        [32 x i8],
        [32 x i8]* @MAX_TOKENS_ERR,
        i64 0,
        i64 0
      )
  ) noreturn

  unreachable

create:
  ; load current element and associate
  ; it to the provided lexeme and size

  br label %getElement
  
getElement:
  ; %len = load i8, i8* @Length
  ; %offset = zext i8 %len to i64

  %target = getelementptr
    [80 x %Token],
    [80 x %Token]* @Reader.Tokens,
    i8 0,
    i8 %len

  %target.lexeme = getelementptr
    %Token,
    %Token* %target,
    i32 0,
    i32 0        ; lexeme

  %target.size = getelementptr
    %Token,
    %Token* %target,
    i32 0,
    i32 1        ; size

  br label %assign

assign:
  store i8* %lexeme, i8** %target.lexeme
  store i32 %size, i32* %target.size

  br label %insert

insert:
  ; cast token* to an i8* and insert to LL

  %pointer = bitcast %Token* %target to i8*

  call void
    @LL.Insert(i8* %pointer)

  br label %advance

advance:
  %incLen = add nsw i8 1, %len
  store i8 %incLen, i8* @Length

  ret void
}

define void @Reader.tokenize(i8* %str) {

  ; substring store
  %substring = alloca i8*

  ; substring length store
  %substringLen = alloca i32

  %fullLen = call i32
    @strlen(i8* %str)

  store i8* %str,     i8** %substring
  store i32 %fullLen, i32* %substringLen

  br label %loop

loop:
  %s = load i8*, i8** %substring

  %result = call i32
    @Regex.Match(i8* %s)

  br label %getBounds

getBounds:
  %start = call i32
    @Regex.GetCaptureBegin()
  %end = call i32
    @Regex.GetCaptureEnd()

  %size = sub nsw i32 %end, %start

  ; fetching substring length
  %len = load i32, i32* %substringLen

  ;--DEBUG--
  call void
    @Regex.Inspect()
  ;--END--

  ; end >= len
  %atEnd = icmp sge i32 %end, %len
  br i1 %atEnd, label %done, label %insert

insert:
  ; cutting start things such as whitespace
  %cut = getelementptr
    i8,
    i8* %s,
    i32 %start

  call void
    @Reader.Token(i8* %cut, i32 %size)

  br label %nextMatch

nextMatch:
  %next = getelementptr
    i8,
    i8* %s,
    i32 %end

  store i8* %next, i8** %substring

  ; updating
  br label %newSubstring

newSubstring:
  ; in case nothing was captured (i.e. whitespace)
  ; %end < 1
  %noSize = icmp slt i32 %end, 1
  br i1 %noSize, label %subLenDecrement, label %subLenCalculate

subLenDecrement:
  %decSubLen = sub nsw i32 %len, 1
  store i32 %decSubLen, i32* %substringLen

  br label %continue

subLenCalculate:
  %calcSubLen = sub nsw i32 %len, %end
  store i32 %calcSubLen, i32* %substringLen

  br label %continue

continue:
  br label %loop

done:
  ret void
}

define void @read_str(i8* %str) {

  call void
    @Reader.Init()

  call void
    @Reader.tokenize(i8* %str)

; call void
;   @Reader.read_form()

  ret void
}

define void @Reader.Clean() {

  ;--DEBUG--
  call void
    @Token.Inspect()

  call void
    @LL.Inspect()
  ;--END--

  ; resetting tokens
  store i8 0, i8* @Length

  call void
    @Regex.Clean()

  call void
    @LL.Clean()

  ret void
}

declare void @Die(i8*) noreturn

declare void @LL.Init()
declare i8*  @LL.Next()
declare i8*  @LL.Peek()
declare void @LL.Insert(i8*)
declare void @LL.Clean()

declare void @Regex.Init(i8*)
declare i32  @Regex.Match(i8*)
declare i32  @Regex.GetCaptureBegin()
declare i32  @Regex.GetCaptureEnd()
declare void @Regex.Clean()

declare i32  @strlen(i8*)

;--DEBUG--
declare void @LL.Inspect()
declare void @Regex.Inspect()
declare void @Token.Inspect()
;--END--
