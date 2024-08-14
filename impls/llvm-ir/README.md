call void
    @LL.Init()

  call void
    @LL.Insert(
      i8* getelementptr (
        [7 x i8],
        [7 x i8]* @Greeting,
        i64 0,
        i64 0
      )
  )

  call void
    @LL.Insert(
      i8* getelementptr (
        [74 x i8],
        [74 x i8]* @RE,
        i64 0,
        i64 0
      )
  )

  ; skipping Head
  call i8*
    @LL.Next()

  %p = call i8*
    @LL.Peek()
  %n = call i8*
    @LL.Next()
  %m = call i8*
    @LL.Next()

  call i32
    @puts(
      i8* %p
  )
  call i32
    @puts(
      i8* %n
  )
  call i32
    @puts(
      i8* %m
  )

  call void
    @LL.Clear()


