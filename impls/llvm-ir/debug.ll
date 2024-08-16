
@Regex.Groups = external global [10 x i32]
@PCRE_DBG_FMT = constant [26 x i8] c"Group: %d, Bounds: %d-%d\0A\00"

define void @Regex.Inspect() {
  %pf1 = getelementptr
    [10 x i32],
    [10 x i32]* @Regex.Groups,
    i64 0,
    i64 0
  %pf2 = getelementptr
    [10 x i32],
    [10 x i32]* @Regex.Groups,
    i64 0,
    i64 1
  %ps1 = getelementptr
    [10 x i32],
    [10 x i32]* @Regex.Groups,
    i64 0,
    i64 2
  %ps2 = getelementptr
    [10 x i32],
    [10 x i32]* @Regex.Groups,
    i64 0,
    i64 3

  %f1 = load i32, i32* %pf1
  %f2 = load i32, i32* %pf2
  %s1 = load i32, i32* %ps1
  %s2 = load i32, i32* %ps2

  call i32 (i8*, ...)
    @printf(
      i8* getelementptr (
        [26 x i8],
        [26 x i8]* @PCRE_DBG_FMT,
        i64 0,
        i64 0
      ),
      i32 1,
      i32 %f1,
      i32 %f2
  )
  call i32 (i8*, ...)
    @printf(
      i8* getelementptr (
        [26 x i8],
        [26 x i8]* @PCRE_DBG_FMT,
        i64 0,
        i64 0
      ),
      i32 2,
      i32 %s1,
      i32 %s2
  )

  ret void
}

%LL         = type { i8*, %LL* }
@LL.Head    = external global %LL
@LL_DBG_FMT = constant [23 x i8] c"Address: %p, Data: %p\0A\00"

define void @LL.Inspect() {

  %curr = alloca %LL*

  store %LL* @LL.Head, %LL** %curr

  br label %iter

iter:
  ; loading current node ( stack allocated LL* )
  %node = load %LL*, %LL** %curr

  %data = call i8*
    @LL.GetData(%LL* %node)

  call i32 (i8*, ...)
    @printf(
      i8* getelementptr (
        [23 x i8],
        [23 x i8]* @LL_DBG_FMT,
        i64 0,
        i64 0
      ),
      %LL* %node,
      i8* %data
  )

  %next = call %LL*
    @LL.GetNext(%LL* %node)

  br label %check

check:
  ; next
  store %LL* %next, %LL** %curr

  ; is it null tho?
  %isNull = icmp eq %LL* %next, null

  br i1 %isNull, label %done, label %iter

done:
  ret void
}

declare i8*  @LL.GetData(%LL*)
declare %LL* @LL.GetNext(%LL*)

declare i32  @printf(i8*, ...)

