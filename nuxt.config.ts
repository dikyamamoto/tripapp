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
    url: process.env.SUPABASE_URL || 'https://ycbpavascevymilosfdl.supabase.co',
    key: process.env.SUPABASE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljYnBhdmFzY2V2eW1pbG9zZmRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5Njk2MjUsImV4cCI6MjEwMDU0NTYyNX0.sUokP5Z70zaxbdo4Jwyq76seqaoNniDH_qCb8yo_v5c',
    redirect: false
  }
})
