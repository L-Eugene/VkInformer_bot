[![Build Status](https://travis-ci.com/L-Eugene/VkInformer_bot.svg?branch=master)](https://travis-ci.com/L-Eugene/VkInformer_bot)

Rake commands:

rake vk:db:migrate
  Update/Install database using ActiveRecord migrations

rake vk:chat:invert
  Invert chat enabled status. Enables disabled chats and vice versa.

rake vk:debug:on
rake vk:debug:off
  Enable or disable debug logs.

rake vk:token:add[:token]
  Add VK token to list.

rake vk:token:del[:token]
  Remove VK token from list

rake vk:token:stat
  Show token statistic for current date.
