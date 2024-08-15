
%pcre = type opaque

; \5C -> '\' and \22 -> '"'
@TOK = constant [74 x i8] c"[\5Cs,]*(~@|[\5C[\5C]{}()'`~^@]|\5C\22(?:\5C\5C.|[^\5C\5C\5C\22])*\5C\22?|;.*|[^\5Cs\5C[\5C]{}('\5C\22`,;)]*)\00"

define void @Reader.Init() {

  %stdout = load %FILE*, %FILE** @stdout

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

; Probably the hardest function so far
define void @Reader.tokenize() {
  
}

define void @read_str(i8* %str) {

  call void
    @Reader.Init()

  call void
    @Reader.tokenize(i8* %str)

  call void
    @Reader.read_form()
}

define void @Reader.Clean() {

  call void
    @Regex.Clean()

  call void
    @LL.Clean()

  ret void
}

declare void @LL.Init()
declare i8*  @LL.Next()
declare i8*  @LL.Peek()
declare void @LL.Clean()
declare void @LL.Insert(i8*)

declare void @Regex.Init(i8*)
declare void @Regex.Match(i8*)
declare void @Regex.Clean()

