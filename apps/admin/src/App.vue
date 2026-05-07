<template>
  <a-config-provider :locale="zhTW">
    <router-view />
  </a-config-provider>
</template>

<script setup lang="ts">
import zhTW from 'ant-design-vue/es/locale/zh_TW'
</script>
