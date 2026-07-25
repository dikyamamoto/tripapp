// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  ssr: false, // SPAモード
  app: {
    baseURL: '/tripapp/'
  },
  devServer: {
    port: 3001
  },
  css: [
    '~/assets/main.css'
  ],
  modules: [
    '@nuxtjs/supabase'
  ],
  supabase: {
    redirectOptions: {
      login: '/signin',
      callback: '/confirm',
      exclude: ['/', '/signup'], // 未ログインでもアクセス可能なパス
    }
  }
})
