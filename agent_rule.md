# agent_rule

1. keep going without interrupting
2. 需連續提升權限時，統合成一個 script 一次處理；script 存檔規則如下：
   a. 把 n8n 相關中間過程的 script 也存在 `n8n/` 內
   b. repo 及 github 操作相關的 script 不用存
   c. 系統操作相關的 script 存在 repo 根目錄
3. 不管 history，檢查安全性
