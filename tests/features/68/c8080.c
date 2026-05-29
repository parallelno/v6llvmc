typedef unsigned char u8;
typedef unsigned short u16;
typedef signed short s16;

u16 shl_u16_3(u16 x) { return (u16)(x << 3); }
u16 shl_u16_9(u16 x) { return (u16)(x << 9); }
u16 shl_u16_13(u16 x) { return (u16)(x << 13); }
u16 shl_u16_15(u16 x) { return (u16)(x << 15); }

u16 shr_u16_1(u16 x) { return (u16)(x >> 1); }
u16 shr_u16_2(u16 x) { return (u16)(x >> 2); }
u16 shr_u16_7(u16 x) { return (u16)(x >> 7); }
u16 shr_u16_9(u16 x) { return (u16)(x >> 9); }
u16 shr_u16_15(u16 x) { return (u16)(x >> 15); }

s16 sar_i16_7(s16 x) { return (s16)(x >> 7); }
s16 sar_i16_9(s16 x) { return (s16)(x >> 9); }
s16 sar_i16_15(s16 x) { return (s16)(x >> 15); }

volatile u16 g_u = 0x9234;
volatile s16 g_s = (s16)0x9234;
volatile u16 g_out_u;
volatile s16 g_out_s;

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  g_out_u = shl_u16_3(g_u);
  g_out_u = shl_u16_9(g_u);
  g_out_u = shl_u16_13(g_u);
  g_out_u = shl_u16_15(g_u);

  g_out_u = shr_u16_1(g_u);
  g_out_u = shr_u16_2(g_u);
  g_out_u = shr_u16_7(g_u);
  g_out_u = shr_u16_9(g_u);
  g_out_u = shr_u16_15(g_u);

  g_out_s = sar_i16_7(g_s);
  g_out_s = sar_i16_9(g_s);
  g_out_s = sar_i16_15(g_s);
  return 0;
}