command! AssistantToggle lua require'assistant'.toggle_assistant()
command! AssistantHide lua require'assistant'.hide_assistant()
command! AssistantShow lua require'assistant'.show_assistant()
command! AssistantChat lua require'assistant'.move_to_chat()
command! AssistantInput lua require'assistant'.move_to_input()