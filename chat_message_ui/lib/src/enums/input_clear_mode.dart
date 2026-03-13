/// Used to set [Input] clear mode when message is sent.
enum InputClearMode {
  /// Always clear [Input] regardless if message is sent or not.
  always,

  /// Never clear [Input]. You should do it manually, depending on your use case.
  never,
}
