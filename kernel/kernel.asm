
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	cbe78793          	addi	a5,a5,-834 # 80005d20 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffc487f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00039797          	auipc	a5,0x39
    8000047c:	97078793          	addi	a5,a5,-1680 # 80038de8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00039797          	auipc	a5,0x39
    80000a00:	58478793          	addi	a5,a5,1412 # 80039f80 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00039517          	auipc	a0,0x39
    80000ad2:	4b250513          	addi	a0,a0,1202 # 80039f80 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffc5081>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	836080e7          	jalr	-1994(ra) # 800026f4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e9a080e7          	jalr	-358(ra) # 80005d60 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	796080e7          	jalr	1942(ra) # 800026cc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	7b6080e7          	jalr	1974(ra) # 800026f4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	e04080e7          	jalr	-508(ra) # 80005d4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e12080e7          	jalr	-494(ra) # 80005d60 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	fac080e7          	jalr	-84(ra) # 80002f02 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	64c080e7          	jalr	1612(ra) # 800035aa <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	5f2080e7          	jalr	1522(ra) # 80004558 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	efa080e7          	jalr	-262(ra) # 80005e68 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffc5077>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffc5080>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	95448493          	addi	s1,s1,-1708 # 800111a0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	33aa0a13          	addi	s4,s4,826 # 80016ba0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28850513          	addi	a0,a0,648 # 80010b70 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	28850513          	addi	a0,a0,648 # 80010b88 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	00010497          	auipc	s1,0x10
    80001914:	89048493          	addi	s1,s1,-1904 # 800111a0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00015997          	auipc	s3,0x15
    80001936:	26e98993          	addi	s3,s3,622 # 80016ba0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	20450513          	addi	a0,a0,516 # 80010ba0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ac70713          	addi	a4,a4,428 # 80010b70 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	d06080e7          	jalr	-762(ra) # 8000270c <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	b0a080e7          	jalr	-1270(ra) # 8000352a <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	13a90913          	addi	s2,s2,314 # 80010b70 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	5de48493          	addi	s1,s1,1502 # 800111a0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	fd690913          	addi	s2,s2,-42 # 80016ba0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	c6a7b023          	sd	a0,-928(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bcc58593          	addi	a1,a1,-1076 # 80008870 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	272080e7          	jalr	626(ra) # 80003f54 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  else if (n < 0)
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if (p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	7d8080e7          	jalr	2008(ra) # 800045ea <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	946080e7          	jalr	-1722(ra) # 8000376a <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d3848493          	addi	s1,s1,-712 # 80010b88 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	cb270713          	addi	a4,a4,-846 # 80010b70 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	cdc70713          	addi	a4,a4,-804 # 80010ba8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	c94a0a13          	addi	s4,s4,-876 # 80010b70 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	cba90913          	addi	s2,s2,-838 # 80016ba0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	2a648493          	addi	s1,s1,678 # 800111a0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	72e080e7          	jalr	1838(ra) # 80002662 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c0670713          	addi	a4,a4,-1018 # 80010b70 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if (p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	be090913          	addi	s2,s2,-1056 # 80010b70 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c0058593          	addi	a1,a1,-1024 # 80010ba8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	6ac080e7          	jalr	1708(ra) # 80002662 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	0d448493          	addi	s1,s1,212 # 800111a0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020d4:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	ac890913          	addi	s2,s2,-1336 # 80016ba0 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if (p != myproc())
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	06048493          	addi	s1,s1,96 # 800111a0 <proc>
      pp->parent = initproc;
    80002148:	00006a17          	auipc	s4,0x6
    8000214c:	7b0a0a13          	addi	s4,s4,1968 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002150:	00015997          	auipc	s3,0x15
    80002154:	a5098993          	addi	s3,s3,-1456 # 80016ba0 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if (pp->parent == p)
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if (p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7547b783          	ld	a5,1876(a5) # 800088f8 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	474080e7          	jalr	1140(ra) # 8000463c <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if (p->ofile[fd])
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	f94080e7          	jalr	-108(ra) # 80004174 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	776080e7          	jalr	1910(ra) # 80003962 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	ffe080e7          	jalr	-2(ra) # 800041f2 <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	98848493          	addi	s1,s1,-1656 # 80010b88 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	f3248493          	addi	s1,s1,-206 # 800111a0 <proc>
    80002276:	00015997          	auipc	s3,0x15
    8000227a:	92a98993          	addi	s3,s3,-1750 # 80016ba0 <tickslock>
  {
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	83650513          	addi	a0,a0,-1994 # 80010b88 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002368:	00015997          	auipc	s3,0x15
    8000236c:	83898993          	addi	s3,s3,-1992 # 80016ba0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	818c0c13          	addi	s8,s8,-2024 # 80010b88 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	e2648493          	addi	s1,s1,-474 # 800111a0 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000e517          	auipc	a0,0xe
    800023bc:	7d050513          	addi	a0,a0,2000 # 80010b88 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000e517          	auipc	a0,0xe
    800023d8:	7b450513          	addi	a0,a0,1972 # 80010b88 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if (pp->parent == p)
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if (!havekids || killed(p))
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	76650513          	addi	a0,a0,1894 # 80010b88 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if (user_dst)
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if (user_src)
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char *)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	dca48493          	addi	s1,s1,-566 # 800112f8 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	7c290913          	addi	s2,s2,1986 # 80016cf8 <u_pstat+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	d78b8b93          	addi	s7,s7,-648 # 800082d0 <states.0>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if (p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <printCharArray>:

void printCharArray(char name[16])
{
    800025b8:	1141                	addi	sp,sp,-16
    800025ba:	e406                	sd	ra,8(sp)
    800025bc:	e022                	sd	s0,0(sp)
    800025be:	0800                	addi	s0,sp,16
    800025c0:	85aa                	mv	a1,a0
  printf("%s\n", name);
    800025c2:	00006517          	auipc	a0,0x6
    800025c6:	cd650513          	addi	a0,a0,-810 # 80008298 <digits+0x258>
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	fc0080e7          	jalr	-64(ra) # 8000058a <printf>
}
    800025d2:	60a2                	ld	ra,8(sp)
    800025d4:	6402                	ld	s0,0(sp)
    800025d6:	0141                	addi	sp,sp,16
    800025d8:	8082                	ret

00000000800025da <getpinfo>:

int getpinfo(struct pstat *pstat)
{
    800025da:	7139                	addi	sp,sp,-64
    800025dc:	fc06                	sd	ra,56(sp)
    800025de:	f822                	sd	s0,48(sp)
    800025e0:	f426                	sd	s1,40(sp)
    800025e2:	f04a                	sd	s2,32(sp)
    800025e4:	ec4e                	sd	s3,24(sp)
    800025e6:	e852                	sd	s4,16(sp)
    800025e8:	e456                	sd	s5,8(sp)
    800025ea:	0080                	addi	s0,sp,64
    800025ec:	8aaa                	mv	s5,a0
  struct proc *p;
  int i = 0;
    800025ee:	4981                	li	s3,0

  // Loop through each process and collect stats
  for (p = proc; p < &proc[NPROC]; p++)
    800025f0:	0000f497          	auipc	s1,0xf
    800025f4:	bb048493          	addi	s1,s1,-1104 # 800111a0 <proc>
    800025f8:	00014a17          	auipc	s4,0x14
    800025fc:	5a8a0a13          	addi	s4,s4,1448 # 80016ba0 <tickslock>
    80002600:	a811                	j	80002614 <getpinfo+0x3a>
      // pstat->state[i] = p->state;

      // Increment the index for the next process
      i++;
    }
    release(&p->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	686080e7          	jalr	1670(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000260c:	16848493          	addi	s1,s1,360
    80002610:	03448f63          	beq	s1,s4,8000264e <getpinfo+0x74>
    acquire(&p->lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	5c0080e7          	jalr	1472(ra) # 80000bd6 <acquire>
    if (p->state != UNUSED)
    8000261e:	4c9c                	lw	a5,24(s1)
    80002620:	d3ed                	beqz	a5,80002602 <getpinfo+0x28>
      pstat->pid[i] = p->pid;
    80002622:	589c                	lw	a5,48(s1)
    80002624:	00299913          	slli	s2,s3,0x2
    80002628:	9956                	add	s2,s2,s5
    8000262a:	00f92023          	sw	a5,0(s2)
      safestrcpy(pstat->name[i], p->name, sizeof(pstat->name[i]));
    8000262e:	01098513          	addi	a0,s3,16
    80002632:	0512                	slli	a0,a0,0x4
    80002634:	4641                	li	a2,16
    80002636:	15848593          	addi	a1,s1,344
    8000263a:	9556                	add	a0,a0,s5
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	7e0080e7          	jalr	2016(ra) # 80000e1c <safestrcpy>
      pstat->sz[i] = p->sz;
    80002644:	64bc                	ld	a5,72(s1)
    80002646:	50f92023          	sw	a5,1280(s2)
      i++;
    8000264a:	2985                	addiw	s3,s3,1
    8000264c:	bf5d                	j	80002602 <getpinfo+0x28>
  }

  // Return the number of processes stored in 'pstat'
  return i;
}
    8000264e:	854e                	mv	a0,s3
    80002650:	70e2                	ld	ra,56(sp)
    80002652:	7442                	ld	s0,48(sp)
    80002654:	74a2                	ld	s1,40(sp)
    80002656:	7902                	ld	s2,32(sp)
    80002658:	69e2                	ld	s3,24(sp)
    8000265a:	6a42                	ld	s4,16(sp)
    8000265c:	6aa2                	ld	s5,8(sp)
    8000265e:	6121                	addi	sp,sp,64
    80002660:	8082                	ret

0000000080002662 <swtch>:
    80002662:	00153023          	sd	ra,0(a0)
    80002666:	00253423          	sd	sp,8(a0)
    8000266a:	e900                	sd	s0,16(a0)
    8000266c:	ed04                	sd	s1,24(a0)
    8000266e:	03253023          	sd	s2,32(a0)
    80002672:	03353423          	sd	s3,40(a0)
    80002676:	03453823          	sd	s4,48(a0)
    8000267a:	03553c23          	sd	s5,56(a0)
    8000267e:	05653023          	sd	s6,64(a0)
    80002682:	05753423          	sd	s7,72(a0)
    80002686:	05853823          	sd	s8,80(a0)
    8000268a:	05953c23          	sd	s9,88(a0)
    8000268e:	07a53023          	sd	s10,96(a0)
    80002692:	07b53423          	sd	s11,104(a0)
    80002696:	0005b083          	ld	ra,0(a1)
    8000269a:	0085b103          	ld	sp,8(a1)
    8000269e:	6980                	ld	s0,16(a1)
    800026a0:	6d84                	ld	s1,24(a1)
    800026a2:	0205b903          	ld	s2,32(a1)
    800026a6:	0285b983          	ld	s3,40(a1)
    800026aa:	0305ba03          	ld	s4,48(a1)
    800026ae:	0385ba83          	ld	s5,56(a1)
    800026b2:	0405bb03          	ld	s6,64(a1)
    800026b6:	0485bb83          	ld	s7,72(a1)
    800026ba:	0505bc03          	ld	s8,80(a1)
    800026be:	0585bc83          	ld	s9,88(a1)
    800026c2:	0605bd03          	ld	s10,96(a1)
    800026c6:	0685bd83          	ld	s11,104(a1)
    800026ca:	8082                	ret

00000000800026cc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026cc:	1141                	addi	sp,sp,-16
    800026ce:	e406                	sd	ra,8(sp)
    800026d0:	e022                	sd	s0,0(sp)
    800026d2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d4:	00006597          	auipc	a1,0x6
    800026d8:	c2c58593          	addi	a1,a1,-980 # 80008300 <states.0+0x30>
    800026dc:	00014517          	auipc	a0,0x14
    800026e0:	4c450513          	addi	a0,a0,1220 # 80016ba0 <tickslock>
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	462080e7          	jalr	1122(ra) # 80000b46 <initlock>
}
    800026ec:	60a2                	ld	ra,8(sp)
    800026ee:	6402                	ld	s0,0(sp)
    800026f0:	0141                	addi	sp,sp,16
    800026f2:	8082                	ret

00000000800026f4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f4:	1141                	addi	sp,sp,-16
    800026f6:	e422                	sd	s0,8(sp)
    800026f8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fa:	00003797          	auipc	a5,0x3
    800026fe:	59678793          	addi	a5,a5,1430 # 80005c90 <kernelvec>
    80002702:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002706:	6422                	ld	s0,8(sp)
    80002708:	0141                	addi	sp,sp,16
    8000270a:	8082                	ret

000000008000270c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000270c:	1141                	addi	sp,sp,-16
    8000270e:	e406                	sd	ra,8(sp)
    80002710:	e022                	sd	s0,0(sp)
    80002712:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	298080e7          	jalr	664(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000271c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002720:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002722:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002726:	00005697          	auipc	a3,0x5
    8000272a:	8da68693          	addi	a3,a3,-1830 # 80007000 <_trampoline>
    8000272e:	00005717          	auipc	a4,0x5
    80002732:	8d270713          	addi	a4,a4,-1838 # 80007000 <_trampoline>
    80002736:	8f15                	sub	a4,a4,a3
    80002738:	040007b7          	lui	a5,0x4000
    8000273c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273e:	07b2                	slli	a5,a5,0xc
    80002740:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002742:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002746:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002748:	18002673          	csrr	a2,satp
    8000274c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274e:	6d30                	ld	a2,88(a0)
    80002750:	6138                	ld	a4,64(a0)
    80002752:	6585                	lui	a1,0x1
    80002754:	972e                	add	a4,a4,a1
    80002756:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002758:	6d38                	ld	a4,88(a0)
    8000275a:	00000617          	auipc	a2,0x0
    8000275e:	13060613          	addi	a2,a2,304 # 8000288a <usertrap>
    80002762:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002764:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002766:	8612                	mv	a2,tp
    80002768:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002772:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002776:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000277a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000277c:	6f18                	ld	a4,24(a4)
    8000277e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002782:	6928                	ld	a0,80(a0)
    80002784:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002786:	00005717          	auipc	a4,0x5
    8000278a:	91670713          	addi	a4,a4,-1770 # 8000709c <userret>
    8000278e:	8f15                	sub	a4,a4,a3
    80002790:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002792:	577d                	li	a4,-1
    80002794:	177e                	slli	a4,a4,0x3f
    80002796:	8d59                	or	a0,a0,a4
    80002798:	9782                	jalr	a5
}
    8000279a:	60a2                	ld	ra,8(sp)
    8000279c:	6402                	ld	s0,0(sp)
    8000279e:	0141                	addi	sp,sp,16
    800027a0:	8082                	ret

00000000800027a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027a2:	1101                	addi	sp,sp,-32
    800027a4:	ec06                	sd	ra,24(sp)
    800027a6:	e822                	sd	s0,16(sp)
    800027a8:	e426                	sd	s1,8(sp)
    800027aa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027ac:	00014497          	auipc	s1,0x14
    800027b0:	3f448493          	addi	s1,s1,1012 # 80016ba0 <tickslock>
    800027b4:	8526                	mv	a0,s1
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	420080e7          	jalr	1056(ra) # 80000bd6 <acquire>
  ticks++;
    800027be:	00006517          	auipc	a0,0x6
    800027c2:	14250513          	addi	a0,a0,322 # 80008900 <ticks>
    800027c6:	411c                	lw	a5,0(a0)
    800027c8:	2785                	addiw	a5,a5,1
    800027ca:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027cc:	00000097          	auipc	ra,0x0
    800027d0:	8ec080e7          	jalr	-1812(ra) # 800020b8 <wakeup>
  release(&tickslock);
    800027d4:	8526                	mv	a0,s1
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	4b4080e7          	jalr	1204(ra) # 80000c8a <release>
}
    800027de:	60e2                	ld	ra,24(sp)
    800027e0:	6442                	ld	s0,16(sp)
    800027e2:	64a2                	ld	s1,8(sp)
    800027e4:	6105                	addi	sp,sp,32
    800027e6:	8082                	ret

00000000800027e8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027e8:	1101                	addi	sp,sp,-32
    800027ea:	ec06                	sd	ra,24(sp)
    800027ec:	e822                	sd	s0,16(sp)
    800027ee:	e426                	sd	s1,8(sp)
    800027f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027f6:	00074d63          	bltz	a4,80002810 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027fa:	57fd                	li	a5,-1
    800027fc:	17fe                	slli	a5,a5,0x3f
    800027fe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002800:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002802:	06f70363          	beq	a4,a5,80002868 <devintr+0x80>
  }
}
    80002806:	60e2                	ld	ra,24(sp)
    80002808:	6442                	ld	s0,16(sp)
    8000280a:	64a2                	ld	s1,8(sp)
    8000280c:	6105                	addi	sp,sp,32
    8000280e:	8082                	ret
     (scause & 0xff) == 9){
    80002810:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002814:	46a5                	li	a3,9
    80002816:	fed792e3          	bne	a5,a3,800027fa <devintr+0x12>
    int irq = plic_claim();
    8000281a:	00003097          	auipc	ra,0x3
    8000281e:	57e080e7          	jalr	1406(ra) # 80005d98 <plic_claim>
    80002822:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002824:	47a9                	li	a5,10
    80002826:	02f50763          	beq	a0,a5,80002854 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000282a:	4785                	li	a5,1
    8000282c:	02f50963          	beq	a0,a5,8000285e <devintr+0x76>
    return 1;
    80002830:	4505                	li	a0,1
    } else if(irq){
    80002832:	d8f1                	beqz	s1,80002806 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002834:	85a6                	mv	a1,s1
    80002836:	00006517          	auipc	a0,0x6
    8000283a:	ad250513          	addi	a0,a0,-1326 # 80008308 <states.0+0x38>
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d4c080e7          	jalr	-692(ra) # 8000058a <printf>
      plic_complete(irq);
    80002846:	8526                	mv	a0,s1
    80002848:	00003097          	auipc	ra,0x3
    8000284c:	574080e7          	jalr	1396(ra) # 80005dbc <plic_complete>
    return 1;
    80002850:	4505                	li	a0,1
    80002852:	bf55                	j	80002806 <devintr+0x1e>
      uartintr();
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	144080e7          	jalr	324(ra) # 80000998 <uartintr>
    8000285c:	b7ed                	j	80002846 <devintr+0x5e>
      virtio_disk_intr();
    8000285e:	00004097          	auipc	ra,0x4
    80002862:	a26080e7          	jalr	-1498(ra) # 80006284 <virtio_disk_intr>
    80002866:	b7c5                	j	80002846 <devintr+0x5e>
    if(cpuid() == 0){
    80002868:	fffff097          	auipc	ra,0xfffff
    8000286c:	118080e7          	jalr	280(ra) # 80001980 <cpuid>
    80002870:	c901                	beqz	a0,80002880 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002872:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002876:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002878:	14479073          	csrw	sip,a5
    return 2;
    8000287c:	4509                	li	a0,2
    8000287e:	b761                	j	80002806 <devintr+0x1e>
      clockintr();
    80002880:	00000097          	auipc	ra,0x0
    80002884:	f22080e7          	jalr	-222(ra) # 800027a2 <clockintr>
    80002888:	b7ed                	j	80002872 <devintr+0x8a>

000000008000288a <usertrap>:
{
    8000288a:	1101                	addi	sp,sp,-32
    8000288c:	ec06                	sd	ra,24(sp)
    8000288e:	e822                	sd	s0,16(sp)
    80002890:	e426                	sd	s1,8(sp)
    80002892:	e04a                	sd	s2,0(sp)
    80002894:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002896:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289a:	1007f793          	andi	a5,a5,256
    8000289e:	e3b1                	bnez	a5,800028e2 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a0:	00003797          	auipc	a5,0x3
    800028a4:	3f078793          	addi	a5,a5,1008 # 80005c90 <kernelvec>
    800028a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	100080e7          	jalr	256(ra) # 800019ac <myproc>
    800028b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b8:	14102773          	csrr	a4,sepc
    800028bc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028be:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c2:	47a1                	li	a5,8
    800028c4:	02f70763          	beq	a4,a5,800028f2 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	f20080e7          	jalr	-224(ra) # 800027e8 <devintr>
    800028d0:	892a                	mv	s2,a0
    800028d2:	c151                	beqz	a0,80002956 <usertrap+0xcc>
  if(killed(p))
    800028d4:	8526                	mv	a0,s1
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	a26080e7          	jalr	-1498(ra) # 800022fc <killed>
    800028de:	c929                	beqz	a0,80002930 <usertrap+0xa6>
    800028e0:	a099                	j	80002926 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	a4650513          	addi	a0,a0,-1466 # 80008328 <states.0+0x58>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c56080e7          	jalr	-938(ra) # 80000540 <panic>
    if(killed(p))
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	a0a080e7          	jalr	-1526(ra) # 800022fc <killed>
    800028fa:	e921                	bnez	a0,8000294a <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028fc:	6cb8                	ld	a4,88(s1)
    800028fe:	6f1c                	ld	a5,24(a4)
    80002900:	0791                	addi	a5,a5,4
    80002902:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002904:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002908:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290c:	10079073          	csrw	sstatus,a5
    syscall();
    80002910:	00000097          	auipc	ra,0x0
    80002914:	2d4080e7          	jalr	724(ra) # 80002be4 <syscall>
  if(killed(p))
    80002918:	8526                	mv	a0,s1
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	9e2080e7          	jalr	-1566(ra) # 800022fc <killed>
    80002922:	c911                	beqz	a0,80002936 <usertrap+0xac>
    80002924:	4901                	li	s2,0
    exit(-1);
    80002926:	557d                	li	a0,-1
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	860080e7          	jalr	-1952(ra) # 80002188 <exit>
  if(which_dev == 2)
    80002930:	4789                	li	a5,2
    80002932:	04f90f63          	beq	s2,a5,80002990 <usertrap+0x106>
  usertrapret();
    80002936:	00000097          	auipc	ra,0x0
    8000293a:	dd6080e7          	jalr	-554(ra) # 8000270c <usertrapret>
}
    8000293e:	60e2                	ld	ra,24(sp)
    80002940:	6442                	ld	s0,16(sp)
    80002942:	64a2                	ld	s1,8(sp)
    80002944:	6902                	ld	s2,0(sp)
    80002946:	6105                	addi	sp,sp,32
    80002948:	8082                	ret
      exit(-1);
    8000294a:	557d                	li	a0,-1
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	83c080e7          	jalr	-1988(ra) # 80002188 <exit>
    80002954:	b765                	j	800028fc <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002956:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000295a:	5890                	lw	a2,48(s1)
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	9ec50513          	addi	a0,a0,-1556 # 80008348 <states.0+0x78>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c26080e7          	jalr	-986(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000296c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002970:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002974:	00006517          	auipc	a0,0x6
    80002978:	a0450513          	addi	a0,a0,-1532 # 80008378 <states.0+0xa8>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	c0e080e7          	jalr	-1010(ra) # 8000058a <printf>
    setkilled(p);
    80002984:	8526                	mv	a0,s1
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	94a080e7          	jalr	-1718(ra) # 800022d0 <setkilled>
    8000298e:	b769                	j	80002918 <usertrap+0x8e>
    yield();
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	688080e7          	jalr	1672(ra) # 80002018 <yield>
    80002998:	bf79                	j	80002936 <usertrap+0xac>

000000008000299a <kerneltrap>:
{
    8000299a:	7179                	addi	sp,sp,-48
    8000299c:	f406                	sd	ra,40(sp)
    8000299e:	f022                	sd	s0,32(sp)
    800029a0:	ec26                	sd	s1,24(sp)
    800029a2:	e84a                	sd	s2,16(sp)
    800029a4:	e44e                	sd	s3,8(sp)
    800029a6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029b4:	1004f793          	andi	a5,s1,256
    800029b8:	cb85                	beqz	a5,800029e8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029be:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029c0:	ef85                	bnez	a5,800029f8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029c2:	00000097          	auipc	ra,0x0
    800029c6:	e26080e7          	jalr	-474(ra) # 800027e8 <devintr>
    800029ca:	cd1d                	beqz	a0,80002a08 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029cc:	4789                	li	a5,2
    800029ce:	06f50a63          	beq	a0,a5,80002a42 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d6:	10049073          	csrw	sstatus,s1
}
    800029da:	70a2                	ld	ra,40(sp)
    800029dc:	7402                	ld	s0,32(sp)
    800029de:	64e2                	ld	s1,24(sp)
    800029e0:	6942                	ld	s2,16(sp)
    800029e2:	69a2                	ld	s3,8(sp)
    800029e4:	6145                	addi	sp,sp,48
    800029e6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029e8:	00006517          	auipc	a0,0x6
    800029ec:	9b050513          	addi	a0,a0,-1616 # 80008398 <states.0+0xc8>
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	b50080e7          	jalr	-1200(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029f8:	00006517          	auipc	a0,0x6
    800029fc:	9c850513          	addi	a0,a0,-1592 # 800083c0 <states.0+0xf0>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b40080e7          	jalr	-1216(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a08:	85ce                	mv	a1,s3
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	9d650513          	addi	a0,a0,-1578 # 800083e0 <states.0+0x110>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b78080e7          	jalr	-1160(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a1e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	9ce50513          	addi	a0,a0,-1586 # 800083f0 <states.0+0x120>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b60080e7          	jalr	-1184(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	9d650513          	addi	a0,a0,-1578 # 80008408 <states.0+0x138>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	b06080e7          	jalr	-1274(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	f6a080e7          	jalr	-150(ra) # 800019ac <myproc>
    80002a4a:	d541                	beqz	a0,800029d2 <kerneltrap+0x38>
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	f60080e7          	jalr	-160(ra) # 800019ac <myproc>
    80002a54:	4d18                	lw	a4,24(a0)
    80002a56:	4791                	li	a5,4
    80002a58:	f6f71de3          	bne	a4,a5,800029d2 <kerneltrap+0x38>
    yield();
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	5bc080e7          	jalr	1468(ra) # 80002018 <yield>
    80002a64:	b7bd                	j	800029d2 <kerneltrap+0x38>

0000000080002a66 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a66:	1101                	addi	sp,sp,-32
    80002a68:	ec06                	sd	ra,24(sp)
    80002a6a:	e822                	sd	s0,16(sp)
    80002a6c:	e426                	sd	s1,8(sp)
    80002a6e:	1000                	addi	s0,sp,32
    80002a70:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	f3a080e7          	jalr	-198(ra) # 800019ac <myproc>
  switch (n)
    80002a7a:	4795                	li	a5,5
    80002a7c:	0497e163          	bltu	a5,s1,80002abe <argraw+0x58>
    80002a80:	048a                	slli	s1,s1,0x2
    80002a82:	00006717          	auipc	a4,0x6
    80002a86:	9be70713          	addi	a4,a4,-1602 # 80008440 <states.0+0x170>
    80002a8a:	94ba                	add	s1,s1,a4
    80002a8c:	409c                	lw	a5,0(s1)
    80002a8e:	97ba                	add	a5,a5,a4
    80002a90:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6105                	addi	sp,sp,32
    80002a9e:	8082                	ret
    return p->trapframe->a1;
    80002aa0:	6d3c                	ld	a5,88(a0)
    80002aa2:	7fa8                	ld	a0,120(a5)
    80002aa4:	bfcd                	j	80002a96 <argraw+0x30>
    return p->trapframe->a2;
    80002aa6:	6d3c                	ld	a5,88(a0)
    80002aa8:	63c8                	ld	a0,128(a5)
    80002aaa:	b7f5                	j	80002a96 <argraw+0x30>
    return p->trapframe->a3;
    80002aac:	6d3c                	ld	a5,88(a0)
    80002aae:	67c8                	ld	a0,136(a5)
    80002ab0:	b7dd                	j	80002a96 <argraw+0x30>
    return p->trapframe->a4;
    80002ab2:	6d3c                	ld	a5,88(a0)
    80002ab4:	6bc8                	ld	a0,144(a5)
    80002ab6:	b7c5                	j	80002a96 <argraw+0x30>
    return p->trapframe->a5;
    80002ab8:	6d3c                	ld	a5,88(a0)
    80002aba:	6fc8                	ld	a0,152(a5)
    80002abc:	bfe9                	j	80002a96 <argraw+0x30>
  panic("argraw");
    80002abe:	00006517          	auipc	a0,0x6
    80002ac2:	95a50513          	addi	a0,a0,-1702 # 80008418 <states.0+0x148>
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	a7a080e7          	jalr	-1414(ra) # 80000540 <panic>

0000000080002ace <fetchaddr>:
{
    80002ace:	1101                	addi	sp,sp,-32
    80002ad0:	ec06                	sd	ra,24(sp)
    80002ad2:	e822                	sd	s0,16(sp)
    80002ad4:	e426                	sd	s1,8(sp)
    80002ad6:	e04a                	sd	s2,0(sp)
    80002ad8:	1000                	addi	s0,sp,32
    80002ada:	84aa                	mv	s1,a0
    80002adc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	ece080e7          	jalr	-306(ra) # 800019ac <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ae6:	653c                	ld	a5,72(a0)
    80002ae8:	02f4f863          	bgeu	s1,a5,80002b18 <fetchaddr+0x4a>
    80002aec:	00848713          	addi	a4,s1,8
    80002af0:	02e7e663          	bltu	a5,a4,80002b1c <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002af4:	46a1                	li	a3,8
    80002af6:	8626                	mv	a2,s1
    80002af8:	85ca                	mv	a1,s2
    80002afa:	6928                	ld	a0,80(a0)
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	bfc080e7          	jalr	-1028(ra) # 800016f8 <copyin>
    80002b04:	00a03533          	snez	a0,a0
    80002b08:	40a00533          	neg	a0,a0
}
    80002b0c:	60e2                	ld	ra,24(sp)
    80002b0e:	6442                	ld	s0,16(sp)
    80002b10:	64a2                	ld	s1,8(sp)
    80002b12:	6902                	ld	s2,0(sp)
    80002b14:	6105                	addi	sp,sp,32
    80002b16:	8082                	ret
    return -1;
    80002b18:	557d                	li	a0,-1
    80002b1a:	bfcd                	j	80002b0c <fetchaddr+0x3e>
    80002b1c:	557d                	li	a0,-1
    80002b1e:	b7fd                	j	80002b0c <fetchaddr+0x3e>

0000000080002b20 <fetchstr>:
{
    80002b20:	7179                	addi	sp,sp,-48
    80002b22:	f406                	sd	ra,40(sp)
    80002b24:	f022                	sd	s0,32(sp)
    80002b26:	ec26                	sd	s1,24(sp)
    80002b28:	e84a                	sd	s2,16(sp)
    80002b2a:	e44e                	sd	s3,8(sp)
    80002b2c:	1800                	addi	s0,sp,48
    80002b2e:	892a                	mv	s2,a0
    80002b30:	84ae                	mv	s1,a1
    80002b32:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	e78080e7          	jalr	-392(ra) # 800019ac <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b3c:	86ce                	mv	a3,s3
    80002b3e:	864a                	mv	a2,s2
    80002b40:	85a6                	mv	a1,s1
    80002b42:	6928                	ld	a0,80(a0)
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	c42080e7          	jalr	-958(ra) # 80001786 <copyinstr>
    80002b4c:	00054e63          	bltz	a0,80002b68 <fetchstr+0x48>
  return strlen(buf);
    80002b50:	8526                	mv	a0,s1
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	2fc080e7          	jalr	764(ra) # 80000e4e <strlen>
}
    80002b5a:	70a2                	ld	ra,40(sp)
    80002b5c:	7402                	ld	s0,32(sp)
    80002b5e:	64e2                	ld	s1,24(sp)
    80002b60:	6942                	ld	s2,16(sp)
    80002b62:	69a2                	ld	s3,8(sp)
    80002b64:	6145                	addi	sp,sp,48
    80002b66:	8082                	ret
    return -1;
    80002b68:	557d                	li	a0,-1
    80002b6a:	bfc5                	j	80002b5a <fetchstr+0x3a>

0000000080002b6c <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002b6c:	1101                	addi	sp,sp,-32
    80002b6e:	ec06                	sd	ra,24(sp)
    80002b70:	e822                	sd	s0,16(sp)
    80002b72:	e426                	sd	s1,8(sp)
    80002b74:	1000                	addi	s0,sp,32
    80002b76:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b78:	00000097          	auipc	ra,0x0
    80002b7c:	eee080e7          	jalr	-274(ra) # 80002a66 <argraw>
    80002b80:	c088                	sw	a0,0(s1)
}
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6105                	addi	sp,sp,32
    80002b8a:	8082                	ret

0000000080002b8c <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002b8c:	1101                	addi	sp,sp,-32
    80002b8e:	ec06                	sd	ra,24(sp)
    80002b90:	e822                	sd	s0,16(sp)
    80002b92:	e426                	sd	s1,8(sp)
    80002b94:	1000                	addi	s0,sp,32
    80002b96:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	ece080e7          	jalr	-306(ra) # 80002a66 <argraw>
    80002ba0:	e088                	sd	a0,0(s1)
}
    80002ba2:	60e2                	ld	ra,24(sp)
    80002ba4:	6442                	ld	s0,16(sp)
    80002ba6:	64a2                	ld	s1,8(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret

0000000080002bac <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002bac:	7179                	addi	sp,sp,-48
    80002bae:	f406                	sd	ra,40(sp)
    80002bb0:	f022                	sd	s0,32(sp)
    80002bb2:	ec26                	sd	s1,24(sp)
    80002bb4:	e84a                	sd	s2,16(sp)
    80002bb6:	1800                	addi	s0,sp,48
    80002bb8:	84ae                	mv	s1,a1
    80002bba:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bbc:	fd840593          	addi	a1,s0,-40
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	fcc080e7          	jalr	-52(ra) # 80002b8c <argaddr>
  return fetchstr(addr, buf, max);
    80002bc8:	864a                	mv	a2,s2
    80002bca:	85a6                	mv	a1,s1
    80002bcc:	fd843503          	ld	a0,-40(s0)
    80002bd0:	00000097          	auipc	ra,0x0
    80002bd4:	f50080e7          	jalr	-176(ra) # 80002b20 <fetchstr>
}
    80002bd8:	70a2                	ld	ra,40(sp)
    80002bda:	7402                	ld	s0,32(sp)
    80002bdc:	64e2                	ld	s1,24(sp)
    80002bde:	6942                	ld	s2,16(sp)
    80002be0:	6145                	addi	sp,sp,48
    80002be2:	8082                	ret

0000000080002be4 <syscall>:
    [SYS_close] sys_close,
    [SYS_processinf] sys_processinf,
};

void syscall(void)
{
    80002be4:	1101                	addi	sp,sp,-32
    80002be6:	ec06                	sd	ra,24(sp)
    80002be8:	e822                	sd	s0,16(sp)
    80002bea:	e426                	sd	s1,8(sp)
    80002bec:	e04a                	sd	s2,0(sp)
    80002bee:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	dbc080e7          	jalr	-580(ra) # 800019ac <myproc>
    80002bf8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bfa:	05853903          	ld	s2,88(a0)
    80002bfe:	0a893783          	ld	a5,168(s2)
    80002c02:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002c06:	37fd                	addiw	a5,a5,-1
    80002c08:	4755                	li	a4,21
    80002c0a:	00f76f63          	bltu	a4,a5,80002c28 <syscall+0x44>
    80002c0e:	00369713          	slli	a4,a3,0x3
    80002c12:	00006797          	auipc	a5,0x6
    80002c16:	84678793          	addi	a5,a5,-1978 # 80008458 <syscalls>
    80002c1a:	97ba                	add	a5,a5,a4
    80002c1c:	639c                	ld	a5,0(a5)
    80002c1e:	c789                	beqz	a5,80002c28 <syscall+0x44>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c20:	9782                	jalr	a5
    80002c22:	06a93823          	sd	a0,112(s2)
    80002c26:	a839                	j	80002c44 <syscall+0x60>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002c28:	15848613          	addi	a2,s1,344
    80002c2c:	588c                	lw	a1,48(s1)
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	7f250513          	addi	a0,a0,2034 # 80008420 <states.0+0x150>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	954080e7          	jalr	-1708(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c3e:	6cbc                	ld	a5,88(s1)
    80002c40:	577d                	li	a4,-1
    80002c42:	fbb8                	sd	a4,112(a5)
  }
}
    80002c44:	60e2                	ld	ra,24(sp)
    80002c46:	6442                	ld	s0,16(sp)
    80002c48:	64a2                	ld	s1,8(sp)
    80002c4a:	6902                	ld	s2,0(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret

0000000080002c50 <sys_exit>:
#include "proc.h"
#include "../user/user_pstat.h"

uint64
sys_exit(void)
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c58:	fec40593          	addi	a1,s0,-20
    80002c5c:	4501                	li	a0,0
    80002c5e:	00000097          	auipc	ra,0x0
    80002c62:	f0e080e7          	jalr	-242(ra) # 80002b6c <argint>
  exit(n);
    80002c66:	fec42503          	lw	a0,-20(s0)
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	51e080e7          	jalr	1310(ra) # 80002188 <exit>
  return 0; // not reached
}
    80002c72:	4501                	li	a0,0
    80002c74:	60e2                	ld	ra,24(sp)
    80002c76:	6442                	ld	s0,16(sp)
    80002c78:	6105                	addi	sp,sp,32
    80002c7a:	8082                	ret

0000000080002c7c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c7c:	1141                	addi	sp,sp,-16
    80002c7e:	e406                	sd	ra,8(sp)
    80002c80:	e022                	sd	s0,0(sp)
    80002c82:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	d28080e7          	jalr	-728(ra) # 800019ac <myproc>
}
    80002c8c:	5908                	lw	a0,48(a0)
    80002c8e:	60a2                	ld	ra,8(sp)
    80002c90:	6402                	ld	s0,0(sp)
    80002c92:	0141                	addi	sp,sp,16
    80002c94:	8082                	ret

0000000080002c96 <sys_fork>:

uint64
sys_fork(void)
{
    80002c96:	1141                	addi	sp,sp,-16
    80002c98:	e406                	sd	ra,8(sp)
    80002c9a:	e022                	sd	s0,0(sp)
    80002c9c:	0800                	addi	s0,sp,16
  return fork();
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	0c4080e7          	jalr	196(ra) # 80001d62 <fork>
}
    80002ca6:	60a2                	ld	ra,8(sp)
    80002ca8:	6402                	ld	s0,0(sp)
    80002caa:	0141                	addi	sp,sp,16
    80002cac:	8082                	ret

0000000080002cae <sys_wait>:

uint64
sys_wait(void)
{
    80002cae:	1101                	addi	sp,sp,-32
    80002cb0:	ec06                	sd	ra,24(sp)
    80002cb2:	e822                	sd	s0,16(sp)
    80002cb4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cb6:	fe840593          	addi	a1,s0,-24
    80002cba:	4501                	li	a0,0
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	ed0080e7          	jalr	-304(ra) # 80002b8c <argaddr>
  return wait(p);
    80002cc4:	fe843503          	ld	a0,-24(s0)
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	666080e7          	jalr	1638(ra) # 8000232e <wait>
}
    80002cd0:	60e2                	ld	ra,24(sp)
    80002cd2:	6442                	ld	s0,16(sp)
    80002cd4:	6105                	addi	sp,sp,32
    80002cd6:	8082                	ret

0000000080002cd8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cd8:	7179                	addi	sp,sp,-48
    80002cda:	f406                	sd	ra,40(sp)
    80002cdc:	f022                	sd	s0,32(sp)
    80002cde:	ec26                	sd	s1,24(sp)
    80002ce0:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ce2:	fdc40593          	addi	a1,s0,-36
    80002ce6:	4501                	li	a0,0
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	e84080e7          	jalr	-380(ra) # 80002b6c <argint>
  addr = myproc()->sz;
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	cbc080e7          	jalr	-836(ra) # 800019ac <myproc>
    80002cf8:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002cfa:	fdc42503          	lw	a0,-36(s0)
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	008080e7          	jalr	8(ra) # 80001d06 <growproc>
    80002d06:	00054863          	bltz	a0,80002d16 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d0a:	8526                	mv	a0,s1
    80002d0c:	70a2                	ld	ra,40(sp)
    80002d0e:	7402                	ld	s0,32(sp)
    80002d10:	64e2                	ld	s1,24(sp)
    80002d12:	6145                	addi	sp,sp,48
    80002d14:	8082                	ret
    return -1;
    80002d16:	54fd                	li	s1,-1
    80002d18:	bfcd                	j	80002d0a <sys_sbrk+0x32>

0000000080002d1a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d1a:	7139                	addi	sp,sp,-64
    80002d1c:	fc06                	sd	ra,56(sp)
    80002d1e:	f822                	sd	s0,48(sp)
    80002d20:	f426                	sd	s1,40(sp)
    80002d22:	f04a                	sd	s2,32(sp)
    80002d24:	ec4e                	sd	s3,24(sp)
    80002d26:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d28:	fcc40593          	addi	a1,s0,-52
    80002d2c:	4501                	li	a0,0
    80002d2e:	00000097          	auipc	ra,0x0
    80002d32:	e3e080e7          	jalr	-450(ra) # 80002b6c <argint>
  acquire(&tickslock);
    80002d36:	00014517          	auipc	a0,0x14
    80002d3a:	e6a50513          	addi	a0,a0,-406 # 80016ba0 <tickslock>
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	e98080e7          	jalr	-360(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d46:	00006917          	auipc	s2,0x6
    80002d4a:	bba92903          	lw	s2,-1094(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80002d4e:	fcc42783          	lw	a5,-52(s0)
    80002d52:	cf9d                	beqz	a5,80002d90 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d54:	00014997          	auipc	s3,0x14
    80002d58:	e4c98993          	addi	s3,s3,-436 # 80016ba0 <tickslock>
    80002d5c:	00006497          	auipc	s1,0x6
    80002d60:	ba448493          	addi	s1,s1,-1116 # 80008900 <ticks>
    if (killed(myproc()))
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	c48080e7          	jalr	-952(ra) # 800019ac <myproc>
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	590080e7          	jalr	1424(ra) # 800022fc <killed>
    80002d74:	ed15                	bnez	a0,80002db0 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d76:	85ce                	mv	a1,s3
    80002d78:	8526                	mv	a0,s1
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	2da080e7          	jalr	730(ra) # 80002054 <sleep>
  while (ticks - ticks0 < n)
    80002d82:	409c                	lw	a5,0(s1)
    80002d84:	412787bb          	subw	a5,a5,s2
    80002d88:	fcc42703          	lw	a4,-52(s0)
    80002d8c:	fce7ece3          	bltu	a5,a4,80002d64 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d90:	00014517          	auipc	a0,0x14
    80002d94:	e1050513          	addi	a0,a0,-496 # 80016ba0 <tickslock>
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	ef2080e7          	jalr	-270(ra) # 80000c8a <release>
  return 0;
    80002da0:	4501                	li	a0,0
}
    80002da2:	70e2                	ld	ra,56(sp)
    80002da4:	7442                	ld	s0,48(sp)
    80002da6:	74a2                	ld	s1,40(sp)
    80002da8:	7902                	ld	s2,32(sp)
    80002daa:	69e2                	ld	s3,24(sp)
    80002dac:	6121                	addi	sp,sp,64
    80002dae:	8082                	ret
      release(&tickslock);
    80002db0:	00014517          	auipc	a0,0x14
    80002db4:	df050513          	addi	a0,a0,-528 # 80016ba0 <tickslock>
    80002db8:	ffffe097          	auipc	ra,0xffffe
    80002dbc:	ed2080e7          	jalr	-302(ra) # 80000c8a <release>
      return -1;
    80002dc0:	557d                	li	a0,-1
    80002dc2:	b7c5                	j	80002da2 <sys_sleep+0x88>

0000000080002dc4 <sys_kill>:

uint64
sys_kill(void)
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002dcc:	fec40593          	addi	a1,s0,-20
    80002dd0:	4501                	li	a0,0
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	d9a080e7          	jalr	-614(ra) # 80002b6c <argint>
  return kill(pid);
    80002dda:	fec42503          	lw	a0,-20(s0)
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	480080e7          	jalr	1152(ra) # 8000225e <kill>
}
    80002de6:	60e2                	ld	ra,24(sp)
    80002de8:	6442                	ld	s0,16(sp)
    80002dea:	6105                	addi	sp,sp,32
    80002dec:	8082                	ret

0000000080002dee <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dee:	1101                	addi	sp,sp,-32
    80002df0:	ec06                	sd	ra,24(sp)
    80002df2:	e822                	sd	s0,16(sp)
    80002df4:	e426                	sd	s1,8(sp)
    80002df6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002df8:	00014517          	auipc	a0,0x14
    80002dfc:	da850513          	addi	a0,a0,-600 # 80016ba0 <tickslock>
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	dd6080e7          	jalr	-554(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002e08:	00006497          	auipc	s1,0x6
    80002e0c:	af84a483          	lw	s1,-1288(s1) # 80008900 <ticks>
  release(&tickslock);
    80002e10:	00014517          	auipc	a0,0x14
    80002e14:	d9050513          	addi	a0,a0,-624 # 80016ba0 <tickslock>
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	e72080e7          	jalr	-398(ra) # 80000c8a <release>
  return xticks;
}
    80002e20:	02049513          	slli	a0,s1,0x20
    80002e24:	9101                	srli	a0,a0,0x20
    80002e26:	60e2                	ld	ra,24(sp)
    80002e28:	6442                	ld	s0,16(sp)
    80002e2a:	64a2                	ld	s1,8(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <sys_processinf>:

struct user_pstat u_pstat[NPROC];
uint64
sys_processinf(void)
{
    80002e30:	9c010113          	addi	sp,sp,-1600
    80002e34:	62113c23          	sd	ra,1592(sp)
    80002e38:	62813823          	sd	s0,1584(sp)
    80002e3c:	62913423          	sd	s1,1576(sp)
    80002e40:	63213023          	sd	s2,1568(sp)
    80002e44:	61313c23          	sd	s3,1560(sp)
    80002e48:	61413823          	sd	s4,1552(sp)
    80002e4c:	61513423          	sd	s5,1544(sp)
    80002e50:	64010413          	addi	s0,sp,1600
  struct pstat k_pstat;
  int procs_active = getpinfo(&k_pstat);
    80002e54:	9c040513          	addi	a0,s0,-1600
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	782080e7          	jalr	1922(ra) # 800025da <getpinfo>
    80002e60:	8a2a                	mv	s4,a0
  for (int i = 0; i < procs_active; i++)
    80002e62:	06a05e63          	blez	a0,80002ede <sys_processinf+0xae>
    80002e66:	9c040893          	addi	a7,s0,-1600
    80002e6a:	00014497          	auipc	s1,0x14
    80002e6e:	d4e48493          	addi	s1,s1,-690 # 80016bb8 <u_pstat>
    80002e72:	00014917          	auipc	s2,0x14
    80002e76:	e4690913          	addi	s2,s2,-442 # 80016cb8 <u_pstat+0x100>
    80002e7a:	ad040613          	addi	a2,s0,-1328
    80002e7e:	fff5099b          	addiw	s3,a0,-1
    80002e82:	02099793          	slli	a5,s3,0x20
    80002e86:	01e7d993          	srli	s3,a5,0x1e
    80002e8a:	00014797          	auipc	a5,0x14
    80002e8e:	d3278793          	addi	a5,a5,-718 # 80016bbc <u_pstat+0x4>
    80002e92:	99be                	add	s3,s3,a5
    80002e94:	884a                	mv	a6,s2
    80002e96:	85a6                	mv	a1,s1
  {
    u_pstat->pid[i] = (int)k_pstat.pid[i];
    80002e98:	0008a783          	lw	a5,0(a7)
    80002e9c:	c19c                	sw	a5,0(a1)
    for (int j = 0; j < 16; j++)
    80002e9e:	ff060793          	addi	a5,a2,-16
    u_pstat->pid[i] = (int)k_pstat.pid[i];
    80002ea2:	8742                	mv	a4,a6
    {
      u_pstat->name[i][j] = k_pstat.name[i][j];
    80002ea4:	0007c683          	lbu	a3,0(a5)
    80002ea8:	00d70023          	sb	a3,0(a4)
    for (int j = 0; j < 16; j++)
    80002eac:	0785                	addi	a5,a5,1
    80002eae:	0705                	addi	a4,a4,1
    80002eb0:	fec79ae3          	bne	a5,a2,80002ea4 <sys_processinf+0x74>
  for (int i = 0; i < procs_active; i++)
    80002eb4:	0891                	addi	a7,a7,4
    80002eb6:	0591                	addi	a1,a1,4 # 1004 <_entry-0x7fffeffc>
    80002eb8:	0841                	addi	a6,a6,16
    80002eba:	0641                	addi	a2,a2,16
    80002ebc:	fd359ee3          	bne	a1,s3,80002e98 <sys_processinf+0x68>
    }
  }
  for (int i = 0; i < procs_active; i++)
  {
    printf("%d  |  %s\n", u_pstat->pid[i], u_pstat->name[i]);
    80002ec0:	00005a97          	auipc	s5,0x5
    80002ec4:	650a8a93          	addi	s5,s5,1616 # 80008510 <syscalls+0xb8>
    80002ec8:	864a                	mv	a2,s2
    80002eca:	408c                	lw	a1,0(s1)
    80002ecc:	8556                	mv	a0,s5
    80002ece:	ffffd097          	auipc	ra,0xffffd
    80002ed2:	6bc080e7          	jalr	1724(ra) # 8000058a <printf>
  for (int i = 0; i < procs_active; i++)
    80002ed6:	0491                	addi	s1,s1,4
    80002ed8:	0941                	addi	s2,s2,16
    80002eda:	ff3497e3          	bne	s1,s3,80002ec8 <sys_processinf+0x98>
  }

  return procs_active;
    80002ede:	8552                	mv	a0,s4
    80002ee0:	63813083          	ld	ra,1592(sp)
    80002ee4:	63013403          	ld	s0,1584(sp)
    80002ee8:	62813483          	ld	s1,1576(sp)
    80002eec:	62013903          	ld	s2,1568(sp)
    80002ef0:	61813983          	ld	s3,1560(sp)
    80002ef4:	61013a03          	ld	s4,1552(sp)
    80002ef8:	60813a83          	ld	s5,1544(sp)
    80002efc:	64010113          	addi	sp,sp,1600
    80002f00:	8082                	ret

0000000080002f02 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f02:	7179                	addi	sp,sp,-48
    80002f04:	f406                	sd	ra,40(sp)
    80002f06:	f022                	sd	s0,32(sp)
    80002f08:	ec26                	sd	s1,24(sp)
    80002f0a:	e84a                	sd	s2,16(sp)
    80002f0c:	e44e                	sd	s3,8(sp)
    80002f0e:	e052                	sd	s4,0(sp)
    80002f10:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f12:	00005597          	auipc	a1,0x5
    80002f16:	60e58593          	addi	a1,a1,1550 # 80008520 <syscalls+0xc8>
    80002f1a:	0002c517          	auipc	a0,0x2c
    80002f1e:	c9e50513          	addi	a0,a0,-866 # 8002ebb8 <bcache>
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	c24080e7          	jalr	-988(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f2a:	00034797          	auipc	a5,0x34
    80002f2e:	c8e78793          	addi	a5,a5,-882 # 80036bb8 <bcache+0x8000>
    80002f32:	00034717          	auipc	a4,0x34
    80002f36:	eee70713          	addi	a4,a4,-274 # 80036e20 <bcache+0x8268>
    80002f3a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f3e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f42:	0002c497          	auipc	s1,0x2c
    80002f46:	c8e48493          	addi	s1,s1,-882 # 8002ebd0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f4a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f4c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f4e:	00005a17          	auipc	s4,0x5
    80002f52:	5daa0a13          	addi	s4,s4,1498 # 80008528 <syscalls+0xd0>
    b->next = bcache.head.next;
    80002f56:	2b893783          	ld	a5,696(s2)
    80002f5a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f5c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f60:	85d2                	mv	a1,s4
    80002f62:	01048513          	addi	a0,s1,16
    80002f66:	00001097          	auipc	ra,0x1
    80002f6a:	4c8080e7          	jalr	1224(ra) # 8000442e <initsleeplock>
    bcache.head.next->prev = b;
    80002f6e:	2b893783          	ld	a5,696(s2)
    80002f72:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f74:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f78:	45848493          	addi	s1,s1,1112
    80002f7c:	fd349de3          	bne	s1,s3,80002f56 <binit+0x54>
  }
}
    80002f80:	70a2                	ld	ra,40(sp)
    80002f82:	7402                	ld	s0,32(sp)
    80002f84:	64e2                	ld	s1,24(sp)
    80002f86:	6942                	ld	s2,16(sp)
    80002f88:	69a2                	ld	s3,8(sp)
    80002f8a:	6a02                	ld	s4,0(sp)
    80002f8c:	6145                	addi	sp,sp,48
    80002f8e:	8082                	ret

0000000080002f90 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f90:	7179                	addi	sp,sp,-48
    80002f92:	f406                	sd	ra,40(sp)
    80002f94:	f022                	sd	s0,32(sp)
    80002f96:	ec26                	sd	s1,24(sp)
    80002f98:	e84a                	sd	s2,16(sp)
    80002f9a:	e44e                	sd	s3,8(sp)
    80002f9c:	1800                	addi	s0,sp,48
    80002f9e:	892a                	mv	s2,a0
    80002fa0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fa2:	0002c517          	auipc	a0,0x2c
    80002fa6:	c1650513          	addi	a0,a0,-1002 # 8002ebb8 <bcache>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	c2c080e7          	jalr	-980(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb2:	00034497          	auipc	s1,0x34
    80002fb6:	ebe4b483          	ld	s1,-322(s1) # 80036e70 <bcache+0x82b8>
    80002fba:	00034797          	auipc	a5,0x34
    80002fbe:	e6678793          	addi	a5,a5,-410 # 80036e20 <bcache+0x8268>
    80002fc2:	02f48f63          	beq	s1,a5,80003000 <bread+0x70>
    80002fc6:	873e                	mv	a4,a5
    80002fc8:	a021                	j	80002fd0 <bread+0x40>
    80002fca:	68a4                	ld	s1,80(s1)
    80002fcc:	02e48a63          	beq	s1,a4,80003000 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fd0:	449c                	lw	a5,8(s1)
    80002fd2:	ff279ce3          	bne	a5,s2,80002fca <bread+0x3a>
    80002fd6:	44dc                	lw	a5,12(s1)
    80002fd8:	ff3799e3          	bne	a5,s3,80002fca <bread+0x3a>
      b->refcnt++;
    80002fdc:	40bc                	lw	a5,64(s1)
    80002fde:	2785                	addiw	a5,a5,1
    80002fe0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe2:	0002c517          	auipc	a0,0x2c
    80002fe6:	bd650513          	addi	a0,a0,-1066 # 8002ebb8 <bcache>
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	ca0080e7          	jalr	-864(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ff2:	01048513          	addi	a0,s1,16
    80002ff6:	00001097          	auipc	ra,0x1
    80002ffa:	472080e7          	jalr	1138(ra) # 80004468 <acquiresleep>
      return b;
    80002ffe:	a8b9                	j	8000305c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003000:	00034497          	auipc	s1,0x34
    80003004:	e684b483          	ld	s1,-408(s1) # 80036e68 <bcache+0x82b0>
    80003008:	00034797          	auipc	a5,0x34
    8000300c:	e1878793          	addi	a5,a5,-488 # 80036e20 <bcache+0x8268>
    80003010:	00f48863          	beq	s1,a5,80003020 <bread+0x90>
    80003014:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003016:	40bc                	lw	a5,64(s1)
    80003018:	cf81                	beqz	a5,80003030 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000301a:	64a4                	ld	s1,72(s1)
    8000301c:	fee49de3          	bne	s1,a4,80003016 <bread+0x86>
  panic("bget: no buffers");
    80003020:	00005517          	auipc	a0,0x5
    80003024:	51050513          	addi	a0,a0,1296 # 80008530 <syscalls+0xd8>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	518080e7          	jalr	1304(ra) # 80000540 <panic>
      b->dev = dev;
    80003030:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003034:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003038:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000303c:	4785                	li	a5,1
    8000303e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003040:	0002c517          	auipc	a0,0x2c
    80003044:	b7850513          	addi	a0,a0,-1160 # 8002ebb8 <bcache>
    80003048:	ffffe097          	auipc	ra,0xffffe
    8000304c:	c42080e7          	jalr	-958(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003050:	01048513          	addi	a0,s1,16
    80003054:	00001097          	auipc	ra,0x1
    80003058:	414080e7          	jalr	1044(ra) # 80004468 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000305c:	409c                	lw	a5,0(s1)
    8000305e:	cb89                	beqz	a5,80003070 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003060:	8526                	mv	a0,s1
    80003062:	70a2                	ld	ra,40(sp)
    80003064:	7402                	ld	s0,32(sp)
    80003066:	64e2                	ld	s1,24(sp)
    80003068:	6942                	ld	s2,16(sp)
    8000306a:	69a2                	ld	s3,8(sp)
    8000306c:	6145                	addi	sp,sp,48
    8000306e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003070:	4581                	li	a1,0
    80003072:	8526                	mv	a0,s1
    80003074:	00003097          	auipc	ra,0x3
    80003078:	fde080e7          	jalr	-34(ra) # 80006052 <virtio_disk_rw>
    b->valid = 1;
    8000307c:	4785                	li	a5,1
    8000307e:	c09c                	sw	a5,0(s1)
  return b;
    80003080:	b7c5                	j	80003060 <bread+0xd0>

0000000080003082 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	1000                	addi	s0,sp,32
    8000308c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000308e:	0541                	addi	a0,a0,16
    80003090:	00001097          	auipc	ra,0x1
    80003094:	472080e7          	jalr	1138(ra) # 80004502 <holdingsleep>
    80003098:	cd01                	beqz	a0,800030b0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000309a:	4585                	li	a1,1
    8000309c:	8526                	mv	a0,s1
    8000309e:	00003097          	auipc	ra,0x3
    800030a2:	fb4080e7          	jalr	-76(ra) # 80006052 <virtio_disk_rw>
}
    800030a6:	60e2                	ld	ra,24(sp)
    800030a8:	6442                	ld	s0,16(sp)
    800030aa:	64a2                	ld	s1,8(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret
    panic("bwrite");
    800030b0:	00005517          	auipc	a0,0x5
    800030b4:	49850513          	addi	a0,a0,1176 # 80008548 <syscalls+0xf0>
    800030b8:	ffffd097          	auipc	ra,0xffffd
    800030bc:	488080e7          	jalr	1160(ra) # 80000540 <panic>

00000000800030c0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030c0:	1101                	addi	sp,sp,-32
    800030c2:	ec06                	sd	ra,24(sp)
    800030c4:	e822                	sd	s0,16(sp)
    800030c6:	e426                	sd	s1,8(sp)
    800030c8:	e04a                	sd	s2,0(sp)
    800030ca:	1000                	addi	s0,sp,32
    800030cc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ce:	01050913          	addi	s2,a0,16
    800030d2:	854a                	mv	a0,s2
    800030d4:	00001097          	auipc	ra,0x1
    800030d8:	42e080e7          	jalr	1070(ra) # 80004502 <holdingsleep>
    800030dc:	c92d                	beqz	a0,8000314e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030de:	854a                	mv	a0,s2
    800030e0:	00001097          	auipc	ra,0x1
    800030e4:	3de080e7          	jalr	990(ra) # 800044be <releasesleep>

  acquire(&bcache.lock);
    800030e8:	0002c517          	auipc	a0,0x2c
    800030ec:	ad050513          	addi	a0,a0,-1328 # 8002ebb8 <bcache>
    800030f0:	ffffe097          	auipc	ra,0xffffe
    800030f4:	ae6080e7          	jalr	-1306(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030f8:	40bc                	lw	a5,64(s1)
    800030fa:	37fd                	addiw	a5,a5,-1
    800030fc:	0007871b          	sext.w	a4,a5
    80003100:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003102:	eb05                	bnez	a4,80003132 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003104:	68bc                	ld	a5,80(s1)
    80003106:	64b8                	ld	a4,72(s1)
    80003108:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000310a:	64bc                	ld	a5,72(s1)
    8000310c:	68b8                	ld	a4,80(s1)
    8000310e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003110:	00034797          	auipc	a5,0x34
    80003114:	aa878793          	addi	a5,a5,-1368 # 80036bb8 <bcache+0x8000>
    80003118:	2b87b703          	ld	a4,696(a5)
    8000311c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000311e:	00034717          	auipc	a4,0x34
    80003122:	d0270713          	addi	a4,a4,-766 # 80036e20 <bcache+0x8268>
    80003126:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003128:	2b87b703          	ld	a4,696(a5)
    8000312c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000312e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003132:	0002c517          	auipc	a0,0x2c
    80003136:	a8650513          	addi	a0,a0,-1402 # 8002ebb8 <bcache>
    8000313a:	ffffe097          	auipc	ra,0xffffe
    8000313e:	b50080e7          	jalr	-1200(ra) # 80000c8a <release>
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6902                	ld	s2,0(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret
    panic("brelse");
    8000314e:	00005517          	auipc	a0,0x5
    80003152:	40250513          	addi	a0,a0,1026 # 80008550 <syscalls+0xf8>
    80003156:	ffffd097          	auipc	ra,0xffffd
    8000315a:	3ea080e7          	jalr	1002(ra) # 80000540 <panic>

000000008000315e <bpin>:

void
bpin(struct buf *b) {
    8000315e:	1101                	addi	sp,sp,-32
    80003160:	ec06                	sd	ra,24(sp)
    80003162:	e822                	sd	s0,16(sp)
    80003164:	e426                	sd	s1,8(sp)
    80003166:	1000                	addi	s0,sp,32
    80003168:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000316a:	0002c517          	auipc	a0,0x2c
    8000316e:	a4e50513          	addi	a0,a0,-1458 # 8002ebb8 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	a64080e7          	jalr	-1436(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000317a:	40bc                	lw	a5,64(s1)
    8000317c:	2785                	addiw	a5,a5,1
    8000317e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003180:	0002c517          	auipc	a0,0x2c
    80003184:	a3850513          	addi	a0,a0,-1480 # 8002ebb8 <bcache>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	b02080e7          	jalr	-1278(ra) # 80000c8a <release>
}
    80003190:	60e2                	ld	ra,24(sp)
    80003192:	6442                	ld	s0,16(sp)
    80003194:	64a2                	ld	s1,8(sp)
    80003196:	6105                	addi	sp,sp,32
    80003198:	8082                	ret

000000008000319a <bunpin>:

void
bunpin(struct buf *b) {
    8000319a:	1101                	addi	sp,sp,-32
    8000319c:	ec06                	sd	ra,24(sp)
    8000319e:	e822                	sd	s0,16(sp)
    800031a0:	e426                	sd	s1,8(sp)
    800031a2:	1000                	addi	s0,sp,32
    800031a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a6:	0002c517          	auipc	a0,0x2c
    800031aa:	a1250513          	addi	a0,a0,-1518 # 8002ebb8 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	a28080e7          	jalr	-1496(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031b6:	40bc                	lw	a5,64(s1)
    800031b8:	37fd                	addiw	a5,a5,-1
    800031ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031bc:	0002c517          	auipc	a0,0x2c
    800031c0:	9fc50513          	addi	a0,a0,-1540 # 8002ebb8 <bcache>
    800031c4:	ffffe097          	auipc	ra,0xffffe
    800031c8:	ac6080e7          	jalr	-1338(ra) # 80000c8a <release>
}
    800031cc:	60e2                	ld	ra,24(sp)
    800031ce:	6442                	ld	s0,16(sp)
    800031d0:	64a2                	ld	s1,8(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret

00000000800031d6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031d6:	1101                	addi	sp,sp,-32
    800031d8:	ec06                	sd	ra,24(sp)
    800031da:	e822                	sd	s0,16(sp)
    800031dc:	e426                	sd	s1,8(sp)
    800031de:	e04a                	sd	s2,0(sp)
    800031e0:	1000                	addi	s0,sp,32
    800031e2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031e4:	00d5d59b          	srliw	a1,a1,0xd
    800031e8:	00034797          	auipc	a5,0x34
    800031ec:	0ac7a783          	lw	a5,172(a5) # 80037294 <sb+0x1c>
    800031f0:	9dbd                	addw	a1,a1,a5
    800031f2:	00000097          	auipc	ra,0x0
    800031f6:	d9e080e7          	jalr	-610(ra) # 80002f90 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031fa:	0074f713          	andi	a4,s1,7
    800031fe:	4785                	li	a5,1
    80003200:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003204:	14ce                	slli	s1,s1,0x33
    80003206:	90d9                	srli	s1,s1,0x36
    80003208:	00950733          	add	a4,a0,s1
    8000320c:	05874703          	lbu	a4,88(a4)
    80003210:	00e7f6b3          	and	a3,a5,a4
    80003214:	c69d                	beqz	a3,80003242 <bfree+0x6c>
    80003216:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003218:	94aa                	add	s1,s1,a0
    8000321a:	fff7c793          	not	a5,a5
    8000321e:	8f7d                	and	a4,a4,a5
    80003220:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003224:	00001097          	auipc	ra,0x1
    80003228:	126080e7          	jalr	294(ra) # 8000434a <log_write>
  brelse(bp);
    8000322c:	854a                	mv	a0,s2
    8000322e:	00000097          	auipc	ra,0x0
    80003232:	e92080e7          	jalr	-366(ra) # 800030c0 <brelse>
}
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	64a2                	ld	s1,8(sp)
    8000323c:	6902                	ld	s2,0(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret
    panic("freeing free block");
    80003242:	00005517          	auipc	a0,0x5
    80003246:	31650513          	addi	a0,a0,790 # 80008558 <syscalls+0x100>
    8000324a:	ffffd097          	auipc	ra,0xffffd
    8000324e:	2f6080e7          	jalr	758(ra) # 80000540 <panic>

0000000080003252 <balloc>:
{
    80003252:	711d                	addi	sp,sp,-96
    80003254:	ec86                	sd	ra,88(sp)
    80003256:	e8a2                	sd	s0,80(sp)
    80003258:	e4a6                	sd	s1,72(sp)
    8000325a:	e0ca                	sd	s2,64(sp)
    8000325c:	fc4e                	sd	s3,56(sp)
    8000325e:	f852                	sd	s4,48(sp)
    80003260:	f456                	sd	s5,40(sp)
    80003262:	f05a                	sd	s6,32(sp)
    80003264:	ec5e                	sd	s7,24(sp)
    80003266:	e862                	sd	s8,16(sp)
    80003268:	e466                	sd	s9,8(sp)
    8000326a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000326c:	00034797          	auipc	a5,0x34
    80003270:	0107a783          	lw	a5,16(a5) # 8003727c <sb+0x4>
    80003274:	cff5                	beqz	a5,80003370 <balloc+0x11e>
    80003276:	8baa                	mv	s7,a0
    80003278:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000327a:	00034b17          	auipc	s6,0x34
    8000327e:	ffeb0b13          	addi	s6,s6,-2 # 80037278 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003282:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003284:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003286:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003288:	6c89                	lui	s9,0x2
    8000328a:	a061                	j	80003312 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000328c:	97ca                	add	a5,a5,s2
    8000328e:	8e55                	or	a2,a2,a3
    80003290:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003294:	854a                	mv	a0,s2
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	0b4080e7          	jalr	180(ra) # 8000434a <log_write>
        brelse(bp);
    8000329e:	854a                	mv	a0,s2
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	e20080e7          	jalr	-480(ra) # 800030c0 <brelse>
  bp = bread(dev, bno);
    800032a8:	85a6                	mv	a1,s1
    800032aa:	855e                	mv	a0,s7
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	ce4080e7          	jalr	-796(ra) # 80002f90 <bread>
    800032b4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032b6:	40000613          	li	a2,1024
    800032ba:	4581                	li	a1,0
    800032bc:	05850513          	addi	a0,a0,88
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	a12080e7          	jalr	-1518(ra) # 80000cd2 <memset>
  log_write(bp);
    800032c8:	854a                	mv	a0,s2
    800032ca:	00001097          	auipc	ra,0x1
    800032ce:	080080e7          	jalr	128(ra) # 8000434a <log_write>
  brelse(bp);
    800032d2:	854a                	mv	a0,s2
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	dec080e7          	jalr	-532(ra) # 800030c0 <brelse>
}
    800032dc:	8526                	mv	a0,s1
    800032de:	60e6                	ld	ra,88(sp)
    800032e0:	6446                	ld	s0,80(sp)
    800032e2:	64a6                	ld	s1,72(sp)
    800032e4:	6906                	ld	s2,64(sp)
    800032e6:	79e2                	ld	s3,56(sp)
    800032e8:	7a42                	ld	s4,48(sp)
    800032ea:	7aa2                	ld	s5,40(sp)
    800032ec:	7b02                	ld	s6,32(sp)
    800032ee:	6be2                	ld	s7,24(sp)
    800032f0:	6c42                	ld	s8,16(sp)
    800032f2:	6ca2                	ld	s9,8(sp)
    800032f4:	6125                	addi	sp,sp,96
    800032f6:	8082                	ret
    brelse(bp);
    800032f8:	854a                	mv	a0,s2
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	dc6080e7          	jalr	-570(ra) # 800030c0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003302:	015c87bb          	addw	a5,s9,s5
    80003306:	00078a9b          	sext.w	s5,a5
    8000330a:	004b2703          	lw	a4,4(s6)
    8000330e:	06eaf163          	bgeu	s5,a4,80003370 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003312:	41fad79b          	sraiw	a5,s5,0x1f
    80003316:	0137d79b          	srliw	a5,a5,0x13
    8000331a:	015787bb          	addw	a5,a5,s5
    8000331e:	40d7d79b          	sraiw	a5,a5,0xd
    80003322:	01cb2583          	lw	a1,28(s6)
    80003326:	9dbd                	addw	a1,a1,a5
    80003328:	855e                	mv	a0,s7
    8000332a:	00000097          	auipc	ra,0x0
    8000332e:	c66080e7          	jalr	-922(ra) # 80002f90 <bread>
    80003332:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003334:	004b2503          	lw	a0,4(s6)
    80003338:	000a849b          	sext.w	s1,s5
    8000333c:	8762                	mv	a4,s8
    8000333e:	faa4fde3          	bgeu	s1,a0,800032f8 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003342:	00777693          	andi	a3,a4,7
    80003346:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000334a:	41f7579b          	sraiw	a5,a4,0x1f
    8000334e:	01d7d79b          	srliw	a5,a5,0x1d
    80003352:	9fb9                	addw	a5,a5,a4
    80003354:	4037d79b          	sraiw	a5,a5,0x3
    80003358:	00f90633          	add	a2,s2,a5
    8000335c:	05864603          	lbu	a2,88(a2)
    80003360:	00c6f5b3          	and	a1,a3,a2
    80003364:	d585                	beqz	a1,8000328c <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003366:	2705                	addiw	a4,a4,1
    80003368:	2485                	addiw	s1,s1,1
    8000336a:	fd471ae3          	bne	a4,s4,8000333e <balloc+0xec>
    8000336e:	b769                	j	800032f8 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003370:	00005517          	auipc	a0,0x5
    80003374:	20050513          	addi	a0,a0,512 # 80008570 <syscalls+0x118>
    80003378:	ffffd097          	auipc	ra,0xffffd
    8000337c:	212080e7          	jalr	530(ra) # 8000058a <printf>
  return 0;
    80003380:	4481                	li	s1,0
    80003382:	bfa9                	j	800032dc <balloc+0x8a>

0000000080003384 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003384:	7179                	addi	sp,sp,-48
    80003386:	f406                	sd	ra,40(sp)
    80003388:	f022                	sd	s0,32(sp)
    8000338a:	ec26                	sd	s1,24(sp)
    8000338c:	e84a                	sd	s2,16(sp)
    8000338e:	e44e                	sd	s3,8(sp)
    80003390:	e052                	sd	s4,0(sp)
    80003392:	1800                	addi	s0,sp,48
    80003394:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003396:	47ad                	li	a5,11
    80003398:	02b7e863          	bltu	a5,a1,800033c8 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000339c:	02059793          	slli	a5,a1,0x20
    800033a0:	01e7d593          	srli	a1,a5,0x1e
    800033a4:	00b504b3          	add	s1,a0,a1
    800033a8:	0504a903          	lw	s2,80(s1)
    800033ac:	06091e63          	bnez	s2,80003428 <bmap+0xa4>
      addr = balloc(ip->dev);
    800033b0:	4108                	lw	a0,0(a0)
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	ea0080e7          	jalr	-352(ra) # 80003252 <balloc>
    800033ba:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033be:	06090563          	beqz	s2,80003428 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800033c2:	0524a823          	sw	s2,80(s1)
    800033c6:	a08d                	j	80003428 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033c8:	ff45849b          	addiw	s1,a1,-12
    800033cc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033d0:	0ff00793          	li	a5,255
    800033d4:	08e7e563          	bltu	a5,a4,8000345e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033d8:	08052903          	lw	s2,128(a0)
    800033dc:	00091d63          	bnez	s2,800033f6 <bmap+0x72>
      addr = balloc(ip->dev);
    800033e0:	4108                	lw	a0,0(a0)
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	e70080e7          	jalr	-400(ra) # 80003252 <balloc>
    800033ea:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033ee:	02090d63          	beqz	s2,80003428 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033f2:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033f6:	85ca                	mv	a1,s2
    800033f8:	0009a503          	lw	a0,0(s3)
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	b94080e7          	jalr	-1132(ra) # 80002f90 <bread>
    80003404:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003406:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000340a:	02049713          	slli	a4,s1,0x20
    8000340e:	01e75593          	srli	a1,a4,0x1e
    80003412:	00b784b3          	add	s1,a5,a1
    80003416:	0004a903          	lw	s2,0(s1)
    8000341a:	02090063          	beqz	s2,8000343a <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000341e:	8552                	mv	a0,s4
    80003420:	00000097          	auipc	ra,0x0
    80003424:	ca0080e7          	jalr	-864(ra) # 800030c0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003428:	854a                	mv	a0,s2
    8000342a:	70a2                	ld	ra,40(sp)
    8000342c:	7402                	ld	s0,32(sp)
    8000342e:	64e2                	ld	s1,24(sp)
    80003430:	6942                	ld	s2,16(sp)
    80003432:	69a2                	ld	s3,8(sp)
    80003434:	6a02                	ld	s4,0(sp)
    80003436:	6145                	addi	sp,sp,48
    80003438:	8082                	ret
      addr = balloc(ip->dev);
    8000343a:	0009a503          	lw	a0,0(s3)
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	e14080e7          	jalr	-492(ra) # 80003252 <balloc>
    80003446:	0005091b          	sext.w	s2,a0
      if(addr){
    8000344a:	fc090ae3          	beqz	s2,8000341e <bmap+0x9a>
        a[bn] = addr;
    8000344e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003452:	8552                	mv	a0,s4
    80003454:	00001097          	auipc	ra,0x1
    80003458:	ef6080e7          	jalr	-266(ra) # 8000434a <log_write>
    8000345c:	b7c9                	j	8000341e <bmap+0x9a>
  panic("bmap: out of range");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	12a50513          	addi	a0,a0,298 # 80008588 <syscalls+0x130>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	0da080e7          	jalr	218(ra) # 80000540 <panic>

000000008000346e <iget>:
{
    8000346e:	7179                	addi	sp,sp,-48
    80003470:	f406                	sd	ra,40(sp)
    80003472:	f022                	sd	s0,32(sp)
    80003474:	ec26                	sd	s1,24(sp)
    80003476:	e84a                	sd	s2,16(sp)
    80003478:	e44e                	sd	s3,8(sp)
    8000347a:	e052                	sd	s4,0(sp)
    8000347c:	1800                	addi	s0,sp,48
    8000347e:	89aa                	mv	s3,a0
    80003480:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003482:	00034517          	auipc	a0,0x34
    80003486:	e1650513          	addi	a0,a0,-490 # 80037298 <itable>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	74c080e7          	jalr	1868(ra) # 80000bd6 <acquire>
  empty = 0;
    80003492:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003494:	00034497          	auipc	s1,0x34
    80003498:	e1c48493          	addi	s1,s1,-484 # 800372b0 <itable+0x18>
    8000349c:	00036697          	auipc	a3,0x36
    800034a0:	8a468693          	addi	a3,a3,-1884 # 80038d40 <log>
    800034a4:	a039                	j	800034b2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034a6:	02090b63          	beqz	s2,800034dc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034aa:	08848493          	addi	s1,s1,136
    800034ae:	02d48a63          	beq	s1,a3,800034e2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034b2:	449c                	lw	a5,8(s1)
    800034b4:	fef059e3          	blez	a5,800034a6 <iget+0x38>
    800034b8:	4098                	lw	a4,0(s1)
    800034ba:	ff3716e3          	bne	a4,s3,800034a6 <iget+0x38>
    800034be:	40d8                	lw	a4,4(s1)
    800034c0:	ff4713e3          	bne	a4,s4,800034a6 <iget+0x38>
      ip->ref++;
    800034c4:	2785                	addiw	a5,a5,1
    800034c6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034c8:	00034517          	auipc	a0,0x34
    800034cc:	dd050513          	addi	a0,a0,-560 # 80037298 <itable>
    800034d0:	ffffd097          	auipc	ra,0xffffd
    800034d4:	7ba080e7          	jalr	1978(ra) # 80000c8a <release>
      return ip;
    800034d8:	8926                	mv	s2,s1
    800034da:	a03d                	j	80003508 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034dc:	f7f9                	bnez	a5,800034aa <iget+0x3c>
    800034de:	8926                	mv	s2,s1
    800034e0:	b7e9                	j	800034aa <iget+0x3c>
  if(empty == 0)
    800034e2:	02090c63          	beqz	s2,8000351a <iget+0xac>
  ip->dev = dev;
    800034e6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034ea:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034ee:	4785                	li	a5,1
    800034f0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034f4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034f8:	00034517          	auipc	a0,0x34
    800034fc:	da050513          	addi	a0,a0,-608 # 80037298 <itable>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	78a080e7          	jalr	1930(ra) # 80000c8a <release>
}
    80003508:	854a                	mv	a0,s2
    8000350a:	70a2                	ld	ra,40(sp)
    8000350c:	7402                	ld	s0,32(sp)
    8000350e:	64e2                	ld	s1,24(sp)
    80003510:	6942                	ld	s2,16(sp)
    80003512:	69a2                	ld	s3,8(sp)
    80003514:	6a02                	ld	s4,0(sp)
    80003516:	6145                	addi	sp,sp,48
    80003518:	8082                	ret
    panic("iget: no inodes");
    8000351a:	00005517          	auipc	a0,0x5
    8000351e:	08650513          	addi	a0,a0,134 # 800085a0 <syscalls+0x148>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	01e080e7          	jalr	30(ra) # 80000540 <panic>

000000008000352a <fsinit>:
fsinit(int dev) {
    8000352a:	7179                	addi	sp,sp,-48
    8000352c:	f406                	sd	ra,40(sp)
    8000352e:	f022                	sd	s0,32(sp)
    80003530:	ec26                	sd	s1,24(sp)
    80003532:	e84a                	sd	s2,16(sp)
    80003534:	e44e                	sd	s3,8(sp)
    80003536:	1800                	addi	s0,sp,48
    80003538:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000353a:	4585                	li	a1,1
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	a54080e7          	jalr	-1452(ra) # 80002f90 <bread>
    80003544:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003546:	00034997          	auipc	s3,0x34
    8000354a:	d3298993          	addi	s3,s3,-718 # 80037278 <sb>
    8000354e:	02000613          	li	a2,32
    80003552:	05850593          	addi	a1,a0,88
    80003556:	854e                	mv	a0,s3
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	7d6080e7          	jalr	2006(ra) # 80000d2e <memmove>
  brelse(bp);
    80003560:	8526                	mv	a0,s1
    80003562:	00000097          	auipc	ra,0x0
    80003566:	b5e080e7          	jalr	-1186(ra) # 800030c0 <brelse>
  if(sb.magic != FSMAGIC)
    8000356a:	0009a703          	lw	a4,0(s3)
    8000356e:	102037b7          	lui	a5,0x10203
    80003572:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003576:	02f71263          	bne	a4,a5,8000359a <fsinit+0x70>
  initlog(dev, &sb);
    8000357a:	00034597          	auipc	a1,0x34
    8000357e:	cfe58593          	addi	a1,a1,-770 # 80037278 <sb>
    80003582:	854a                	mv	a0,s2
    80003584:	00001097          	auipc	ra,0x1
    80003588:	b4a080e7          	jalr	-1206(ra) # 800040ce <initlog>
}
    8000358c:	70a2                	ld	ra,40(sp)
    8000358e:	7402                	ld	s0,32(sp)
    80003590:	64e2                	ld	s1,24(sp)
    80003592:	6942                	ld	s2,16(sp)
    80003594:	69a2                	ld	s3,8(sp)
    80003596:	6145                	addi	sp,sp,48
    80003598:	8082                	ret
    panic("invalid file system");
    8000359a:	00005517          	auipc	a0,0x5
    8000359e:	01650513          	addi	a0,a0,22 # 800085b0 <syscalls+0x158>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	f9e080e7          	jalr	-98(ra) # 80000540 <panic>

00000000800035aa <iinit>:
{
    800035aa:	7179                	addi	sp,sp,-48
    800035ac:	f406                	sd	ra,40(sp)
    800035ae:	f022                	sd	s0,32(sp)
    800035b0:	ec26                	sd	s1,24(sp)
    800035b2:	e84a                	sd	s2,16(sp)
    800035b4:	e44e                	sd	s3,8(sp)
    800035b6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035b8:	00005597          	auipc	a1,0x5
    800035bc:	01058593          	addi	a1,a1,16 # 800085c8 <syscalls+0x170>
    800035c0:	00034517          	auipc	a0,0x34
    800035c4:	cd850513          	addi	a0,a0,-808 # 80037298 <itable>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	57e080e7          	jalr	1406(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035d0:	00034497          	auipc	s1,0x34
    800035d4:	cf048493          	addi	s1,s1,-784 # 800372c0 <itable+0x28>
    800035d8:	00035997          	auipc	s3,0x35
    800035dc:	77898993          	addi	s3,s3,1912 # 80038d50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035e0:	00005917          	auipc	s2,0x5
    800035e4:	ff090913          	addi	s2,s2,-16 # 800085d0 <syscalls+0x178>
    800035e8:	85ca                	mv	a1,s2
    800035ea:	8526                	mv	a0,s1
    800035ec:	00001097          	auipc	ra,0x1
    800035f0:	e42080e7          	jalr	-446(ra) # 8000442e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035f4:	08848493          	addi	s1,s1,136
    800035f8:	ff3498e3          	bne	s1,s3,800035e8 <iinit+0x3e>
}
    800035fc:	70a2                	ld	ra,40(sp)
    800035fe:	7402                	ld	s0,32(sp)
    80003600:	64e2                	ld	s1,24(sp)
    80003602:	6942                	ld	s2,16(sp)
    80003604:	69a2                	ld	s3,8(sp)
    80003606:	6145                	addi	sp,sp,48
    80003608:	8082                	ret

000000008000360a <ialloc>:
{
    8000360a:	715d                	addi	sp,sp,-80
    8000360c:	e486                	sd	ra,72(sp)
    8000360e:	e0a2                	sd	s0,64(sp)
    80003610:	fc26                	sd	s1,56(sp)
    80003612:	f84a                	sd	s2,48(sp)
    80003614:	f44e                	sd	s3,40(sp)
    80003616:	f052                	sd	s4,32(sp)
    80003618:	ec56                	sd	s5,24(sp)
    8000361a:	e85a                	sd	s6,16(sp)
    8000361c:	e45e                	sd	s7,8(sp)
    8000361e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003620:	00034717          	auipc	a4,0x34
    80003624:	c6472703          	lw	a4,-924(a4) # 80037284 <sb+0xc>
    80003628:	4785                	li	a5,1
    8000362a:	04e7fa63          	bgeu	a5,a4,8000367e <ialloc+0x74>
    8000362e:	8aaa                	mv	s5,a0
    80003630:	8bae                	mv	s7,a1
    80003632:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003634:	00034a17          	auipc	s4,0x34
    80003638:	c44a0a13          	addi	s4,s4,-956 # 80037278 <sb>
    8000363c:	00048b1b          	sext.w	s6,s1
    80003640:	0044d593          	srli	a1,s1,0x4
    80003644:	018a2783          	lw	a5,24(s4)
    80003648:	9dbd                	addw	a1,a1,a5
    8000364a:	8556                	mv	a0,s5
    8000364c:	00000097          	auipc	ra,0x0
    80003650:	944080e7          	jalr	-1724(ra) # 80002f90 <bread>
    80003654:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003656:	05850993          	addi	s3,a0,88
    8000365a:	00f4f793          	andi	a5,s1,15
    8000365e:	079a                	slli	a5,a5,0x6
    80003660:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003662:	00099783          	lh	a5,0(s3)
    80003666:	c3a1                	beqz	a5,800036a6 <ialloc+0x9c>
    brelse(bp);
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	a58080e7          	jalr	-1448(ra) # 800030c0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003670:	0485                	addi	s1,s1,1
    80003672:	00ca2703          	lw	a4,12(s4)
    80003676:	0004879b          	sext.w	a5,s1
    8000367a:	fce7e1e3          	bltu	a5,a4,8000363c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000367e:	00005517          	auipc	a0,0x5
    80003682:	f5a50513          	addi	a0,a0,-166 # 800085d8 <syscalls+0x180>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	f04080e7          	jalr	-252(ra) # 8000058a <printf>
  return 0;
    8000368e:	4501                	li	a0,0
}
    80003690:	60a6                	ld	ra,72(sp)
    80003692:	6406                	ld	s0,64(sp)
    80003694:	74e2                	ld	s1,56(sp)
    80003696:	7942                	ld	s2,48(sp)
    80003698:	79a2                	ld	s3,40(sp)
    8000369a:	7a02                	ld	s4,32(sp)
    8000369c:	6ae2                	ld	s5,24(sp)
    8000369e:	6b42                	ld	s6,16(sp)
    800036a0:	6ba2                	ld	s7,8(sp)
    800036a2:	6161                	addi	sp,sp,80
    800036a4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036a6:	04000613          	li	a2,64
    800036aa:	4581                	li	a1,0
    800036ac:	854e                	mv	a0,s3
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	624080e7          	jalr	1572(ra) # 80000cd2 <memset>
      dip->type = type;
    800036b6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ba:	854a                	mv	a0,s2
    800036bc:	00001097          	auipc	ra,0x1
    800036c0:	c8e080e7          	jalr	-882(ra) # 8000434a <log_write>
      brelse(bp);
    800036c4:	854a                	mv	a0,s2
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	9fa080e7          	jalr	-1542(ra) # 800030c0 <brelse>
      return iget(dev, inum);
    800036ce:	85da                	mv	a1,s6
    800036d0:	8556                	mv	a0,s5
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	d9c080e7          	jalr	-612(ra) # 8000346e <iget>
    800036da:	bf5d                	j	80003690 <ialloc+0x86>

00000000800036dc <iupdate>:
{
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	e04a                	sd	s2,0(sp)
    800036e6:	1000                	addi	s0,sp,32
    800036e8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ea:	415c                	lw	a5,4(a0)
    800036ec:	0047d79b          	srliw	a5,a5,0x4
    800036f0:	00034597          	auipc	a1,0x34
    800036f4:	ba05a583          	lw	a1,-1120(a1) # 80037290 <sb+0x18>
    800036f8:	9dbd                	addw	a1,a1,a5
    800036fa:	4108                	lw	a0,0(a0)
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	894080e7          	jalr	-1900(ra) # 80002f90 <bread>
    80003704:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003706:	05850793          	addi	a5,a0,88
    8000370a:	40d8                	lw	a4,4(s1)
    8000370c:	8b3d                	andi	a4,a4,15
    8000370e:	071a                	slli	a4,a4,0x6
    80003710:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003712:	04449703          	lh	a4,68(s1)
    80003716:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000371a:	04649703          	lh	a4,70(s1)
    8000371e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003722:	04849703          	lh	a4,72(s1)
    80003726:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000372a:	04a49703          	lh	a4,74(s1)
    8000372e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003732:	44f8                	lw	a4,76(s1)
    80003734:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003736:	03400613          	li	a2,52
    8000373a:	05048593          	addi	a1,s1,80
    8000373e:	00c78513          	addi	a0,a5,12
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	5ec080e7          	jalr	1516(ra) # 80000d2e <memmove>
  log_write(bp);
    8000374a:	854a                	mv	a0,s2
    8000374c:	00001097          	auipc	ra,0x1
    80003750:	bfe080e7          	jalr	-1026(ra) # 8000434a <log_write>
  brelse(bp);
    80003754:	854a                	mv	a0,s2
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	96a080e7          	jalr	-1686(ra) # 800030c0 <brelse>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6902                	ld	s2,0(sp)
    80003766:	6105                	addi	sp,sp,32
    80003768:	8082                	ret

000000008000376a <idup>:
{
    8000376a:	1101                	addi	sp,sp,-32
    8000376c:	ec06                	sd	ra,24(sp)
    8000376e:	e822                	sd	s0,16(sp)
    80003770:	e426                	sd	s1,8(sp)
    80003772:	1000                	addi	s0,sp,32
    80003774:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003776:	00034517          	auipc	a0,0x34
    8000377a:	b2250513          	addi	a0,a0,-1246 # 80037298 <itable>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	458080e7          	jalr	1112(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003786:	449c                	lw	a5,8(s1)
    80003788:	2785                	addiw	a5,a5,1
    8000378a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000378c:	00034517          	auipc	a0,0x34
    80003790:	b0c50513          	addi	a0,a0,-1268 # 80037298 <itable>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	4f6080e7          	jalr	1270(ra) # 80000c8a <release>
}
    8000379c:	8526                	mv	a0,s1
    8000379e:	60e2                	ld	ra,24(sp)
    800037a0:	6442                	ld	s0,16(sp)
    800037a2:	64a2                	ld	s1,8(sp)
    800037a4:	6105                	addi	sp,sp,32
    800037a6:	8082                	ret

00000000800037a8 <ilock>:
{
    800037a8:	1101                	addi	sp,sp,-32
    800037aa:	ec06                	sd	ra,24(sp)
    800037ac:	e822                	sd	s0,16(sp)
    800037ae:	e426                	sd	s1,8(sp)
    800037b0:	e04a                	sd	s2,0(sp)
    800037b2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037b4:	c115                	beqz	a0,800037d8 <ilock+0x30>
    800037b6:	84aa                	mv	s1,a0
    800037b8:	451c                	lw	a5,8(a0)
    800037ba:	00f05f63          	blez	a5,800037d8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037be:	0541                	addi	a0,a0,16
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	ca8080e7          	jalr	-856(ra) # 80004468 <acquiresleep>
  if(ip->valid == 0){
    800037c8:	40bc                	lw	a5,64(s1)
    800037ca:	cf99                	beqz	a5,800037e8 <ilock+0x40>
}
    800037cc:	60e2                	ld	ra,24(sp)
    800037ce:	6442                	ld	s0,16(sp)
    800037d0:	64a2                	ld	s1,8(sp)
    800037d2:	6902                	ld	s2,0(sp)
    800037d4:	6105                	addi	sp,sp,32
    800037d6:	8082                	ret
    panic("ilock");
    800037d8:	00005517          	auipc	a0,0x5
    800037dc:	e1850513          	addi	a0,a0,-488 # 800085f0 <syscalls+0x198>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	d60080e7          	jalr	-672(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037e8:	40dc                	lw	a5,4(s1)
    800037ea:	0047d79b          	srliw	a5,a5,0x4
    800037ee:	00034597          	auipc	a1,0x34
    800037f2:	aa25a583          	lw	a1,-1374(a1) # 80037290 <sb+0x18>
    800037f6:	9dbd                	addw	a1,a1,a5
    800037f8:	4088                	lw	a0,0(s1)
    800037fa:	fffff097          	auipc	ra,0xfffff
    800037fe:	796080e7          	jalr	1942(ra) # 80002f90 <bread>
    80003802:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003804:	05850593          	addi	a1,a0,88
    80003808:	40dc                	lw	a5,4(s1)
    8000380a:	8bbd                	andi	a5,a5,15
    8000380c:	079a                	slli	a5,a5,0x6
    8000380e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003810:	00059783          	lh	a5,0(a1)
    80003814:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003818:	00259783          	lh	a5,2(a1)
    8000381c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003820:	00459783          	lh	a5,4(a1)
    80003824:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003828:	00659783          	lh	a5,6(a1)
    8000382c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003830:	459c                	lw	a5,8(a1)
    80003832:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003834:	03400613          	li	a2,52
    80003838:	05b1                	addi	a1,a1,12
    8000383a:	05048513          	addi	a0,s1,80
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	4f0080e7          	jalr	1264(ra) # 80000d2e <memmove>
    brelse(bp);
    80003846:	854a                	mv	a0,s2
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	878080e7          	jalr	-1928(ra) # 800030c0 <brelse>
    ip->valid = 1;
    80003850:	4785                	li	a5,1
    80003852:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003854:	04449783          	lh	a5,68(s1)
    80003858:	fbb5                	bnez	a5,800037cc <ilock+0x24>
      panic("ilock: no type");
    8000385a:	00005517          	auipc	a0,0x5
    8000385e:	d9e50513          	addi	a0,a0,-610 # 800085f8 <syscalls+0x1a0>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	cde080e7          	jalr	-802(ra) # 80000540 <panic>

000000008000386a <iunlock>:
{
    8000386a:	1101                	addi	sp,sp,-32
    8000386c:	ec06                	sd	ra,24(sp)
    8000386e:	e822                	sd	s0,16(sp)
    80003870:	e426                	sd	s1,8(sp)
    80003872:	e04a                	sd	s2,0(sp)
    80003874:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003876:	c905                	beqz	a0,800038a6 <iunlock+0x3c>
    80003878:	84aa                	mv	s1,a0
    8000387a:	01050913          	addi	s2,a0,16
    8000387e:	854a                	mv	a0,s2
    80003880:	00001097          	auipc	ra,0x1
    80003884:	c82080e7          	jalr	-894(ra) # 80004502 <holdingsleep>
    80003888:	cd19                	beqz	a0,800038a6 <iunlock+0x3c>
    8000388a:	449c                	lw	a5,8(s1)
    8000388c:	00f05d63          	blez	a5,800038a6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003890:	854a                	mv	a0,s2
    80003892:	00001097          	auipc	ra,0x1
    80003896:	c2c080e7          	jalr	-980(ra) # 800044be <releasesleep>
}
    8000389a:	60e2                	ld	ra,24(sp)
    8000389c:	6442                	ld	s0,16(sp)
    8000389e:	64a2                	ld	s1,8(sp)
    800038a0:	6902                	ld	s2,0(sp)
    800038a2:	6105                	addi	sp,sp,32
    800038a4:	8082                	ret
    panic("iunlock");
    800038a6:	00005517          	auipc	a0,0x5
    800038aa:	d6250513          	addi	a0,a0,-670 # 80008608 <syscalls+0x1b0>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	c92080e7          	jalr	-878(ra) # 80000540 <panic>

00000000800038b6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038b6:	7179                	addi	sp,sp,-48
    800038b8:	f406                	sd	ra,40(sp)
    800038ba:	f022                	sd	s0,32(sp)
    800038bc:	ec26                	sd	s1,24(sp)
    800038be:	e84a                	sd	s2,16(sp)
    800038c0:	e44e                	sd	s3,8(sp)
    800038c2:	e052                	sd	s4,0(sp)
    800038c4:	1800                	addi	s0,sp,48
    800038c6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038c8:	05050493          	addi	s1,a0,80
    800038cc:	08050913          	addi	s2,a0,128
    800038d0:	a021                	j	800038d8 <itrunc+0x22>
    800038d2:	0491                	addi	s1,s1,4
    800038d4:	01248d63          	beq	s1,s2,800038ee <itrunc+0x38>
    if(ip->addrs[i]){
    800038d8:	408c                	lw	a1,0(s1)
    800038da:	dde5                	beqz	a1,800038d2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038dc:	0009a503          	lw	a0,0(s3)
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	8f6080e7          	jalr	-1802(ra) # 800031d6 <bfree>
      ip->addrs[i] = 0;
    800038e8:	0004a023          	sw	zero,0(s1)
    800038ec:	b7dd                	j	800038d2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ee:	0809a583          	lw	a1,128(s3)
    800038f2:	e185                	bnez	a1,80003912 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038f4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038f8:	854e                	mv	a0,s3
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	de2080e7          	jalr	-542(ra) # 800036dc <iupdate>
}
    80003902:	70a2                	ld	ra,40(sp)
    80003904:	7402                	ld	s0,32(sp)
    80003906:	64e2                	ld	s1,24(sp)
    80003908:	6942                	ld	s2,16(sp)
    8000390a:	69a2                	ld	s3,8(sp)
    8000390c:	6a02                	ld	s4,0(sp)
    8000390e:	6145                	addi	sp,sp,48
    80003910:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003912:	0009a503          	lw	a0,0(s3)
    80003916:	fffff097          	auipc	ra,0xfffff
    8000391a:	67a080e7          	jalr	1658(ra) # 80002f90 <bread>
    8000391e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003920:	05850493          	addi	s1,a0,88
    80003924:	45850913          	addi	s2,a0,1112
    80003928:	a021                	j	80003930 <itrunc+0x7a>
    8000392a:	0491                	addi	s1,s1,4
    8000392c:	01248b63          	beq	s1,s2,80003942 <itrunc+0x8c>
      if(a[j])
    80003930:	408c                	lw	a1,0(s1)
    80003932:	dde5                	beqz	a1,8000392a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003934:	0009a503          	lw	a0,0(s3)
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	89e080e7          	jalr	-1890(ra) # 800031d6 <bfree>
    80003940:	b7ed                	j	8000392a <itrunc+0x74>
    brelse(bp);
    80003942:	8552                	mv	a0,s4
    80003944:	fffff097          	auipc	ra,0xfffff
    80003948:	77c080e7          	jalr	1916(ra) # 800030c0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000394c:	0809a583          	lw	a1,128(s3)
    80003950:	0009a503          	lw	a0,0(s3)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	882080e7          	jalr	-1918(ra) # 800031d6 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000395c:	0809a023          	sw	zero,128(s3)
    80003960:	bf51                	j	800038f4 <itrunc+0x3e>

0000000080003962 <iput>:
{
    80003962:	1101                	addi	sp,sp,-32
    80003964:	ec06                	sd	ra,24(sp)
    80003966:	e822                	sd	s0,16(sp)
    80003968:	e426                	sd	s1,8(sp)
    8000396a:	e04a                	sd	s2,0(sp)
    8000396c:	1000                	addi	s0,sp,32
    8000396e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003970:	00034517          	auipc	a0,0x34
    80003974:	92850513          	addi	a0,a0,-1752 # 80037298 <itable>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	25e080e7          	jalr	606(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003980:	4498                	lw	a4,8(s1)
    80003982:	4785                	li	a5,1
    80003984:	02f70363          	beq	a4,a5,800039aa <iput+0x48>
  ip->ref--;
    80003988:	449c                	lw	a5,8(s1)
    8000398a:	37fd                	addiw	a5,a5,-1
    8000398c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000398e:	00034517          	auipc	a0,0x34
    80003992:	90a50513          	addi	a0,a0,-1782 # 80037298 <itable>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	2f4080e7          	jalr	756(ra) # 80000c8a <release>
}
    8000399e:	60e2                	ld	ra,24(sp)
    800039a0:	6442                	ld	s0,16(sp)
    800039a2:	64a2                	ld	s1,8(sp)
    800039a4:	6902                	ld	s2,0(sp)
    800039a6:	6105                	addi	sp,sp,32
    800039a8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039aa:	40bc                	lw	a5,64(s1)
    800039ac:	dff1                	beqz	a5,80003988 <iput+0x26>
    800039ae:	04a49783          	lh	a5,74(s1)
    800039b2:	fbf9                	bnez	a5,80003988 <iput+0x26>
    acquiresleep(&ip->lock);
    800039b4:	01048913          	addi	s2,s1,16
    800039b8:	854a                	mv	a0,s2
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	aae080e7          	jalr	-1362(ra) # 80004468 <acquiresleep>
    release(&itable.lock);
    800039c2:	00034517          	auipc	a0,0x34
    800039c6:	8d650513          	addi	a0,a0,-1834 # 80037298 <itable>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	2c0080e7          	jalr	704(ra) # 80000c8a <release>
    itrunc(ip);
    800039d2:	8526                	mv	a0,s1
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	ee2080e7          	jalr	-286(ra) # 800038b6 <itrunc>
    ip->type = 0;
    800039dc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039e0:	8526                	mv	a0,s1
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	cfa080e7          	jalr	-774(ra) # 800036dc <iupdate>
    ip->valid = 0;
    800039ea:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ee:	854a                	mv	a0,s2
    800039f0:	00001097          	auipc	ra,0x1
    800039f4:	ace080e7          	jalr	-1330(ra) # 800044be <releasesleep>
    acquire(&itable.lock);
    800039f8:	00034517          	auipc	a0,0x34
    800039fc:	8a050513          	addi	a0,a0,-1888 # 80037298 <itable>
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	1d6080e7          	jalr	470(ra) # 80000bd6 <acquire>
    80003a08:	b741                	j	80003988 <iput+0x26>

0000000080003a0a <iunlockput>:
{
    80003a0a:	1101                	addi	sp,sp,-32
    80003a0c:	ec06                	sd	ra,24(sp)
    80003a0e:	e822                	sd	s0,16(sp)
    80003a10:	e426                	sd	s1,8(sp)
    80003a12:	1000                	addi	s0,sp,32
    80003a14:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	e54080e7          	jalr	-428(ra) # 8000386a <iunlock>
  iput(ip);
    80003a1e:	8526                	mv	a0,s1
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	f42080e7          	jalr	-190(ra) # 80003962 <iput>
}
    80003a28:	60e2                	ld	ra,24(sp)
    80003a2a:	6442                	ld	s0,16(sp)
    80003a2c:	64a2                	ld	s1,8(sp)
    80003a2e:	6105                	addi	sp,sp,32
    80003a30:	8082                	ret

0000000080003a32 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a32:	1141                	addi	sp,sp,-16
    80003a34:	e422                	sd	s0,8(sp)
    80003a36:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a38:	411c                	lw	a5,0(a0)
    80003a3a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a3c:	415c                	lw	a5,4(a0)
    80003a3e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a40:	04451783          	lh	a5,68(a0)
    80003a44:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a48:	04a51783          	lh	a5,74(a0)
    80003a4c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a50:	04c56783          	lwu	a5,76(a0)
    80003a54:	e99c                	sd	a5,16(a1)
}
    80003a56:	6422                	ld	s0,8(sp)
    80003a58:	0141                	addi	sp,sp,16
    80003a5a:	8082                	ret

0000000080003a5c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a5c:	457c                	lw	a5,76(a0)
    80003a5e:	0ed7e963          	bltu	a5,a3,80003b50 <readi+0xf4>
{
    80003a62:	7159                	addi	sp,sp,-112
    80003a64:	f486                	sd	ra,104(sp)
    80003a66:	f0a2                	sd	s0,96(sp)
    80003a68:	eca6                	sd	s1,88(sp)
    80003a6a:	e8ca                	sd	s2,80(sp)
    80003a6c:	e4ce                	sd	s3,72(sp)
    80003a6e:	e0d2                	sd	s4,64(sp)
    80003a70:	fc56                	sd	s5,56(sp)
    80003a72:	f85a                	sd	s6,48(sp)
    80003a74:	f45e                	sd	s7,40(sp)
    80003a76:	f062                	sd	s8,32(sp)
    80003a78:	ec66                	sd	s9,24(sp)
    80003a7a:	e86a                	sd	s10,16(sp)
    80003a7c:	e46e                	sd	s11,8(sp)
    80003a7e:	1880                	addi	s0,sp,112
    80003a80:	8b2a                	mv	s6,a0
    80003a82:	8bae                	mv	s7,a1
    80003a84:	8a32                	mv	s4,a2
    80003a86:	84b6                	mv	s1,a3
    80003a88:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a8a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a8c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a8e:	0ad76063          	bltu	a4,a3,80003b2e <readi+0xd2>
  if(off + n > ip->size)
    80003a92:	00e7f463          	bgeu	a5,a4,80003a9a <readi+0x3e>
    n = ip->size - off;
    80003a96:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a9a:	0a0a8963          	beqz	s5,80003b4c <readi+0xf0>
    80003a9e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aa4:	5c7d                	li	s8,-1
    80003aa6:	a82d                	j	80003ae0 <readi+0x84>
    80003aa8:	020d1d93          	slli	s11,s10,0x20
    80003aac:	020ddd93          	srli	s11,s11,0x20
    80003ab0:	05890613          	addi	a2,s2,88
    80003ab4:	86ee                	mv	a3,s11
    80003ab6:	963a                	add	a2,a2,a4
    80003ab8:	85d2                	mv	a1,s4
    80003aba:	855e                	mv	a0,s7
    80003abc:	fffff097          	auipc	ra,0xfffff
    80003ac0:	9a0080e7          	jalr	-1632(ra) # 8000245c <either_copyout>
    80003ac4:	05850d63          	beq	a0,s8,80003b1e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ac8:	854a                	mv	a0,s2
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	5f6080e7          	jalr	1526(ra) # 800030c0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad2:	013d09bb          	addw	s3,s10,s3
    80003ad6:	009d04bb          	addw	s1,s10,s1
    80003ada:	9a6e                	add	s4,s4,s11
    80003adc:	0559f763          	bgeu	s3,s5,80003b2a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ae0:	00a4d59b          	srliw	a1,s1,0xa
    80003ae4:	855a                	mv	a0,s6
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	89e080e7          	jalr	-1890(ra) # 80003384 <bmap>
    80003aee:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003af2:	cd85                	beqz	a1,80003b2a <readi+0xce>
    bp = bread(ip->dev, addr);
    80003af4:	000b2503          	lw	a0,0(s6)
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	498080e7          	jalr	1176(ra) # 80002f90 <bread>
    80003b00:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b02:	3ff4f713          	andi	a4,s1,1023
    80003b06:	40ec87bb          	subw	a5,s9,a4
    80003b0a:	413a86bb          	subw	a3,s5,s3
    80003b0e:	8d3e                	mv	s10,a5
    80003b10:	2781                	sext.w	a5,a5
    80003b12:	0006861b          	sext.w	a2,a3
    80003b16:	f8f679e3          	bgeu	a2,a5,80003aa8 <readi+0x4c>
    80003b1a:	8d36                	mv	s10,a3
    80003b1c:	b771                	j	80003aa8 <readi+0x4c>
      brelse(bp);
    80003b1e:	854a                	mv	a0,s2
    80003b20:	fffff097          	auipc	ra,0xfffff
    80003b24:	5a0080e7          	jalr	1440(ra) # 800030c0 <brelse>
      tot = -1;
    80003b28:	59fd                	li	s3,-1
  }
  return tot;
    80003b2a:	0009851b          	sext.w	a0,s3
}
    80003b2e:	70a6                	ld	ra,104(sp)
    80003b30:	7406                	ld	s0,96(sp)
    80003b32:	64e6                	ld	s1,88(sp)
    80003b34:	6946                	ld	s2,80(sp)
    80003b36:	69a6                	ld	s3,72(sp)
    80003b38:	6a06                	ld	s4,64(sp)
    80003b3a:	7ae2                	ld	s5,56(sp)
    80003b3c:	7b42                	ld	s6,48(sp)
    80003b3e:	7ba2                	ld	s7,40(sp)
    80003b40:	7c02                	ld	s8,32(sp)
    80003b42:	6ce2                	ld	s9,24(sp)
    80003b44:	6d42                	ld	s10,16(sp)
    80003b46:	6da2                	ld	s11,8(sp)
    80003b48:	6165                	addi	sp,sp,112
    80003b4a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b4c:	89d6                	mv	s3,s5
    80003b4e:	bff1                	j	80003b2a <readi+0xce>
    return 0;
    80003b50:	4501                	li	a0,0
}
    80003b52:	8082                	ret

0000000080003b54 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b54:	457c                	lw	a5,76(a0)
    80003b56:	10d7e863          	bltu	a5,a3,80003c66 <writei+0x112>
{
    80003b5a:	7159                	addi	sp,sp,-112
    80003b5c:	f486                	sd	ra,104(sp)
    80003b5e:	f0a2                	sd	s0,96(sp)
    80003b60:	eca6                	sd	s1,88(sp)
    80003b62:	e8ca                	sd	s2,80(sp)
    80003b64:	e4ce                	sd	s3,72(sp)
    80003b66:	e0d2                	sd	s4,64(sp)
    80003b68:	fc56                	sd	s5,56(sp)
    80003b6a:	f85a                	sd	s6,48(sp)
    80003b6c:	f45e                	sd	s7,40(sp)
    80003b6e:	f062                	sd	s8,32(sp)
    80003b70:	ec66                	sd	s9,24(sp)
    80003b72:	e86a                	sd	s10,16(sp)
    80003b74:	e46e                	sd	s11,8(sp)
    80003b76:	1880                	addi	s0,sp,112
    80003b78:	8aaa                	mv	s5,a0
    80003b7a:	8bae                	mv	s7,a1
    80003b7c:	8a32                	mv	s4,a2
    80003b7e:	8936                	mv	s2,a3
    80003b80:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b82:	00e687bb          	addw	a5,a3,a4
    80003b86:	0ed7e263          	bltu	a5,a3,80003c6a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b8a:	00043737          	lui	a4,0x43
    80003b8e:	0ef76063          	bltu	a4,a5,80003c6e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b92:	0c0b0863          	beqz	s6,80003c62 <writei+0x10e>
    80003b96:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b98:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b9c:	5c7d                	li	s8,-1
    80003b9e:	a091                	j	80003be2 <writei+0x8e>
    80003ba0:	020d1d93          	slli	s11,s10,0x20
    80003ba4:	020ddd93          	srli	s11,s11,0x20
    80003ba8:	05848513          	addi	a0,s1,88
    80003bac:	86ee                	mv	a3,s11
    80003bae:	8652                	mv	a2,s4
    80003bb0:	85de                	mv	a1,s7
    80003bb2:	953a                	add	a0,a0,a4
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	8fe080e7          	jalr	-1794(ra) # 800024b2 <either_copyin>
    80003bbc:	07850263          	beq	a0,s8,80003c20 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bc0:	8526                	mv	a0,s1
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	788080e7          	jalr	1928(ra) # 8000434a <log_write>
    brelse(bp);
    80003bca:	8526                	mv	a0,s1
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	4f4080e7          	jalr	1268(ra) # 800030c0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bd4:	013d09bb          	addw	s3,s10,s3
    80003bd8:	012d093b          	addw	s2,s10,s2
    80003bdc:	9a6e                	add	s4,s4,s11
    80003bde:	0569f663          	bgeu	s3,s6,80003c2a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003be2:	00a9559b          	srliw	a1,s2,0xa
    80003be6:	8556                	mv	a0,s5
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	79c080e7          	jalr	1948(ra) # 80003384 <bmap>
    80003bf0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bf4:	c99d                	beqz	a1,80003c2a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bf6:	000aa503          	lw	a0,0(s5)
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	396080e7          	jalr	918(ra) # 80002f90 <bread>
    80003c02:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c04:	3ff97713          	andi	a4,s2,1023
    80003c08:	40ec87bb          	subw	a5,s9,a4
    80003c0c:	413b06bb          	subw	a3,s6,s3
    80003c10:	8d3e                	mv	s10,a5
    80003c12:	2781                	sext.w	a5,a5
    80003c14:	0006861b          	sext.w	a2,a3
    80003c18:	f8f674e3          	bgeu	a2,a5,80003ba0 <writei+0x4c>
    80003c1c:	8d36                	mv	s10,a3
    80003c1e:	b749                	j	80003ba0 <writei+0x4c>
      brelse(bp);
    80003c20:	8526                	mv	a0,s1
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	49e080e7          	jalr	1182(ra) # 800030c0 <brelse>
  }

  if(off > ip->size)
    80003c2a:	04caa783          	lw	a5,76(s5)
    80003c2e:	0127f463          	bgeu	a5,s2,80003c36 <writei+0xe2>
    ip->size = off;
    80003c32:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c36:	8556                	mv	a0,s5
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	aa4080e7          	jalr	-1372(ra) # 800036dc <iupdate>

  return tot;
    80003c40:	0009851b          	sext.w	a0,s3
}
    80003c44:	70a6                	ld	ra,104(sp)
    80003c46:	7406                	ld	s0,96(sp)
    80003c48:	64e6                	ld	s1,88(sp)
    80003c4a:	6946                	ld	s2,80(sp)
    80003c4c:	69a6                	ld	s3,72(sp)
    80003c4e:	6a06                	ld	s4,64(sp)
    80003c50:	7ae2                	ld	s5,56(sp)
    80003c52:	7b42                	ld	s6,48(sp)
    80003c54:	7ba2                	ld	s7,40(sp)
    80003c56:	7c02                	ld	s8,32(sp)
    80003c58:	6ce2                	ld	s9,24(sp)
    80003c5a:	6d42                	ld	s10,16(sp)
    80003c5c:	6da2                	ld	s11,8(sp)
    80003c5e:	6165                	addi	sp,sp,112
    80003c60:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c62:	89da                	mv	s3,s6
    80003c64:	bfc9                	j	80003c36 <writei+0xe2>
    return -1;
    80003c66:	557d                	li	a0,-1
}
    80003c68:	8082                	ret
    return -1;
    80003c6a:	557d                	li	a0,-1
    80003c6c:	bfe1                	j	80003c44 <writei+0xf0>
    return -1;
    80003c6e:	557d                	li	a0,-1
    80003c70:	bfd1                	j	80003c44 <writei+0xf0>

0000000080003c72 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c72:	1141                	addi	sp,sp,-16
    80003c74:	e406                	sd	ra,8(sp)
    80003c76:	e022                	sd	s0,0(sp)
    80003c78:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c7a:	4639                	li	a2,14
    80003c7c:	ffffd097          	auipc	ra,0xffffd
    80003c80:	126080e7          	jalr	294(ra) # 80000da2 <strncmp>
}
    80003c84:	60a2                	ld	ra,8(sp)
    80003c86:	6402                	ld	s0,0(sp)
    80003c88:	0141                	addi	sp,sp,16
    80003c8a:	8082                	ret

0000000080003c8c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c8c:	7139                	addi	sp,sp,-64
    80003c8e:	fc06                	sd	ra,56(sp)
    80003c90:	f822                	sd	s0,48(sp)
    80003c92:	f426                	sd	s1,40(sp)
    80003c94:	f04a                	sd	s2,32(sp)
    80003c96:	ec4e                	sd	s3,24(sp)
    80003c98:	e852                	sd	s4,16(sp)
    80003c9a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c9c:	04451703          	lh	a4,68(a0)
    80003ca0:	4785                	li	a5,1
    80003ca2:	00f71a63          	bne	a4,a5,80003cb6 <dirlookup+0x2a>
    80003ca6:	892a                	mv	s2,a0
    80003ca8:	89ae                	mv	s3,a1
    80003caa:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cac:	457c                	lw	a5,76(a0)
    80003cae:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cb0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb2:	e79d                	bnez	a5,80003ce0 <dirlookup+0x54>
    80003cb4:	a8a5                	j	80003d2c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cb6:	00005517          	auipc	a0,0x5
    80003cba:	95a50513          	addi	a0,a0,-1702 # 80008610 <syscalls+0x1b8>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	882080e7          	jalr	-1918(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003cc6:	00005517          	auipc	a0,0x5
    80003cca:	96250513          	addi	a0,a0,-1694 # 80008628 <syscalls+0x1d0>
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	872080e7          	jalr	-1934(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd6:	24c1                	addiw	s1,s1,16
    80003cd8:	04c92783          	lw	a5,76(s2)
    80003cdc:	04f4f763          	bgeu	s1,a5,80003d2a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ce0:	4741                	li	a4,16
    80003ce2:	86a6                	mv	a3,s1
    80003ce4:	fc040613          	addi	a2,s0,-64
    80003ce8:	4581                	li	a1,0
    80003cea:	854a                	mv	a0,s2
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	d70080e7          	jalr	-656(ra) # 80003a5c <readi>
    80003cf4:	47c1                	li	a5,16
    80003cf6:	fcf518e3          	bne	a0,a5,80003cc6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cfa:	fc045783          	lhu	a5,-64(s0)
    80003cfe:	dfe1                	beqz	a5,80003cd6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d00:	fc240593          	addi	a1,s0,-62
    80003d04:	854e                	mv	a0,s3
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	f6c080e7          	jalr	-148(ra) # 80003c72 <namecmp>
    80003d0e:	f561                	bnez	a0,80003cd6 <dirlookup+0x4a>
      if(poff)
    80003d10:	000a0463          	beqz	s4,80003d18 <dirlookup+0x8c>
        *poff = off;
    80003d14:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d18:	fc045583          	lhu	a1,-64(s0)
    80003d1c:	00092503          	lw	a0,0(s2)
    80003d20:	fffff097          	auipc	ra,0xfffff
    80003d24:	74e080e7          	jalr	1870(ra) # 8000346e <iget>
    80003d28:	a011                	j	80003d2c <dirlookup+0xa0>
  return 0;
    80003d2a:	4501                	li	a0,0
}
    80003d2c:	70e2                	ld	ra,56(sp)
    80003d2e:	7442                	ld	s0,48(sp)
    80003d30:	74a2                	ld	s1,40(sp)
    80003d32:	7902                	ld	s2,32(sp)
    80003d34:	69e2                	ld	s3,24(sp)
    80003d36:	6a42                	ld	s4,16(sp)
    80003d38:	6121                	addi	sp,sp,64
    80003d3a:	8082                	ret

0000000080003d3c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d3c:	711d                	addi	sp,sp,-96
    80003d3e:	ec86                	sd	ra,88(sp)
    80003d40:	e8a2                	sd	s0,80(sp)
    80003d42:	e4a6                	sd	s1,72(sp)
    80003d44:	e0ca                	sd	s2,64(sp)
    80003d46:	fc4e                	sd	s3,56(sp)
    80003d48:	f852                	sd	s4,48(sp)
    80003d4a:	f456                	sd	s5,40(sp)
    80003d4c:	f05a                	sd	s6,32(sp)
    80003d4e:	ec5e                	sd	s7,24(sp)
    80003d50:	e862                	sd	s8,16(sp)
    80003d52:	e466                	sd	s9,8(sp)
    80003d54:	e06a                	sd	s10,0(sp)
    80003d56:	1080                	addi	s0,sp,96
    80003d58:	84aa                	mv	s1,a0
    80003d5a:	8b2e                	mv	s6,a1
    80003d5c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d5e:	00054703          	lbu	a4,0(a0)
    80003d62:	02f00793          	li	a5,47
    80003d66:	02f70363          	beq	a4,a5,80003d8c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d6a:	ffffe097          	auipc	ra,0xffffe
    80003d6e:	c42080e7          	jalr	-958(ra) # 800019ac <myproc>
    80003d72:	15053503          	ld	a0,336(a0)
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	9f4080e7          	jalr	-1548(ra) # 8000376a <idup>
    80003d7e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d80:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d84:	4cb5                	li	s9,13
  len = path - s;
    80003d86:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d88:	4c05                	li	s8,1
    80003d8a:	a87d                	j	80003e48 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d8c:	4585                	li	a1,1
    80003d8e:	4505                	li	a0,1
    80003d90:	fffff097          	auipc	ra,0xfffff
    80003d94:	6de080e7          	jalr	1758(ra) # 8000346e <iget>
    80003d98:	8a2a                	mv	s4,a0
    80003d9a:	b7dd                	j	80003d80 <namex+0x44>
      iunlockput(ip);
    80003d9c:	8552                	mv	a0,s4
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	c6c080e7          	jalr	-916(ra) # 80003a0a <iunlockput>
      return 0;
    80003da6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003da8:	8552                	mv	a0,s4
    80003daa:	60e6                	ld	ra,88(sp)
    80003dac:	6446                	ld	s0,80(sp)
    80003dae:	64a6                	ld	s1,72(sp)
    80003db0:	6906                	ld	s2,64(sp)
    80003db2:	79e2                	ld	s3,56(sp)
    80003db4:	7a42                	ld	s4,48(sp)
    80003db6:	7aa2                	ld	s5,40(sp)
    80003db8:	7b02                	ld	s6,32(sp)
    80003dba:	6be2                	ld	s7,24(sp)
    80003dbc:	6c42                	ld	s8,16(sp)
    80003dbe:	6ca2                	ld	s9,8(sp)
    80003dc0:	6d02                	ld	s10,0(sp)
    80003dc2:	6125                	addi	sp,sp,96
    80003dc4:	8082                	ret
      iunlock(ip);
    80003dc6:	8552                	mv	a0,s4
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	aa2080e7          	jalr	-1374(ra) # 8000386a <iunlock>
      return ip;
    80003dd0:	bfe1                	j	80003da8 <namex+0x6c>
      iunlockput(ip);
    80003dd2:	8552                	mv	a0,s4
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	c36080e7          	jalr	-970(ra) # 80003a0a <iunlockput>
      return 0;
    80003ddc:	8a4e                	mv	s4,s3
    80003dde:	b7e9                	j	80003da8 <namex+0x6c>
  len = path - s;
    80003de0:	40998633          	sub	a2,s3,s1
    80003de4:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003de8:	09acd863          	bge	s9,s10,80003e78 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003dec:	4639                	li	a2,14
    80003dee:	85a6                	mv	a1,s1
    80003df0:	8556                	mv	a0,s5
    80003df2:	ffffd097          	auipc	ra,0xffffd
    80003df6:	f3c080e7          	jalr	-196(ra) # 80000d2e <memmove>
    80003dfa:	84ce                	mv	s1,s3
  while(*path == '/')
    80003dfc:	0004c783          	lbu	a5,0(s1)
    80003e00:	01279763          	bne	a5,s2,80003e0e <namex+0xd2>
    path++;
    80003e04:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e06:	0004c783          	lbu	a5,0(s1)
    80003e0a:	ff278de3          	beq	a5,s2,80003e04 <namex+0xc8>
    ilock(ip);
    80003e0e:	8552                	mv	a0,s4
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	998080e7          	jalr	-1640(ra) # 800037a8 <ilock>
    if(ip->type != T_DIR){
    80003e18:	044a1783          	lh	a5,68(s4)
    80003e1c:	f98790e3          	bne	a5,s8,80003d9c <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e20:	000b0563          	beqz	s6,80003e2a <namex+0xee>
    80003e24:	0004c783          	lbu	a5,0(s1)
    80003e28:	dfd9                	beqz	a5,80003dc6 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e2a:	865e                	mv	a2,s7
    80003e2c:	85d6                	mv	a1,s5
    80003e2e:	8552                	mv	a0,s4
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	e5c080e7          	jalr	-420(ra) # 80003c8c <dirlookup>
    80003e38:	89aa                	mv	s3,a0
    80003e3a:	dd41                	beqz	a0,80003dd2 <namex+0x96>
    iunlockput(ip);
    80003e3c:	8552                	mv	a0,s4
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	bcc080e7          	jalr	-1076(ra) # 80003a0a <iunlockput>
    ip = next;
    80003e46:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e48:	0004c783          	lbu	a5,0(s1)
    80003e4c:	01279763          	bne	a5,s2,80003e5a <namex+0x11e>
    path++;
    80003e50:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e52:	0004c783          	lbu	a5,0(s1)
    80003e56:	ff278de3          	beq	a5,s2,80003e50 <namex+0x114>
  if(*path == 0)
    80003e5a:	cb9d                	beqz	a5,80003e90 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e5c:	0004c783          	lbu	a5,0(s1)
    80003e60:	89a6                	mv	s3,s1
  len = path - s;
    80003e62:	8d5e                	mv	s10,s7
    80003e64:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e66:	01278963          	beq	a5,s2,80003e78 <namex+0x13c>
    80003e6a:	dbbd                	beqz	a5,80003de0 <namex+0xa4>
    path++;
    80003e6c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e6e:	0009c783          	lbu	a5,0(s3)
    80003e72:	ff279ce3          	bne	a5,s2,80003e6a <namex+0x12e>
    80003e76:	b7ad                	j	80003de0 <namex+0xa4>
    memmove(name, s, len);
    80003e78:	2601                	sext.w	a2,a2
    80003e7a:	85a6                	mv	a1,s1
    80003e7c:	8556                	mv	a0,s5
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	eb0080e7          	jalr	-336(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e86:	9d56                	add	s10,s10,s5
    80003e88:	000d0023          	sb	zero,0(s10)
    80003e8c:	84ce                	mv	s1,s3
    80003e8e:	b7bd                	j	80003dfc <namex+0xc0>
  if(nameiparent){
    80003e90:	f00b0ce3          	beqz	s6,80003da8 <namex+0x6c>
    iput(ip);
    80003e94:	8552                	mv	a0,s4
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	acc080e7          	jalr	-1332(ra) # 80003962 <iput>
    return 0;
    80003e9e:	4a01                	li	s4,0
    80003ea0:	b721                	j	80003da8 <namex+0x6c>

0000000080003ea2 <dirlink>:
{
    80003ea2:	7139                	addi	sp,sp,-64
    80003ea4:	fc06                	sd	ra,56(sp)
    80003ea6:	f822                	sd	s0,48(sp)
    80003ea8:	f426                	sd	s1,40(sp)
    80003eaa:	f04a                	sd	s2,32(sp)
    80003eac:	ec4e                	sd	s3,24(sp)
    80003eae:	e852                	sd	s4,16(sp)
    80003eb0:	0080                	addi	s0,sp,64
    80003eb2:	892a                	mv	s2,a0
    80003eb4:	8a2e                	mv	s4,a1
    80003eb6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eb8:	4601                	li	a2,0
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	dd2080e7          	jalr	-558(ra) # 80003c8c <dirlookup>
    80003ec2:	e93d                	bnez	a0,80003f38 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec4:	04c92483          	lw	s1,76(s2)
    80003ec8:	c49d                	beqz	s1,80003ef6 <dirlink+0x54>
    80003eca:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ecc:	4741                	li	a4,16
    80003ece:	86a6                	mv	a3,s1
    80003ed0:	fc040613          	addi	a2,s0,-64
    80003ed4:	4581                	li	a1,0
    80003ed6:	854a                	mv	a0,s2
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	b84080e7          	jalr	-1148(ra) # 80003a5c <readi>
    80003ee0:	47c1                	li	a5,16
    80003ee2:	06f51163          	bne	a0,a5,80003f44 <dirlink+0xa2>
    if(de.inum == 0)
    80003ee6:	fc045783          	lhu	a5,-64(s0)
    80003eea:	c791                	beqz	a5,80003ef6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eec:	24c1                	addiw	s1,s1,16
    80003eee:	04c92783          	lw	a5,76(s2)
    80003ef2:	fcf4ede3          	bltu	s1,a5,80003ecc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ef6:	4639                	li	a2,14
    80003ef8:	85d2                	mv	a1,s4
    80003efa:	fc240513          	addi	a0,s0,-62
    80003efe:	ffffd097          	auipc	ra,0xffffd
    80003f02:	ee0080e7          	jalr	-288(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f06:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0a:	4741                	li	a4,16
    80003f0c:	86a6                	mv	a3,s1
    80003f0e:	fc040613          	addi	a2,s0,-64
    80003f12:	4581                	li	a1,0
    80003f14:	854a                	mv	a0,s2
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	c3e080e7          	jalr	-962(ra) # 80003b54 <writei>
    80003f1e:	1541                	addi	a0,a0,-16
    80003f20:	00a03533          	snez	a0,a0
    80003f24:	40a00533          	neg	a0,a0
}
    80003f28:	70e2                	ld	ra,56(sp)
    80003f2a:	7442                	ld	s0,48(sp)
    80003f2c:	74a2                	ld	s1,40(sp)
    80003f2e:	7902                	ld	s2,32(sp)
    80003f30:	69e2                	ld	s3,24(sp)
    80003f32:	6a42                	ld	s4,16(sp)
    80003f34:	6121                	addi	sp,sp,64
    80003f36:	8082                	ret
    iput(ip);
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	a2a080e7          	jalr	-1494(ra) # 80003962 <iput>
    return -1;
    80003f40:	557d                	li	a0,-1
    80003f42:	b7dd                	j	80003f28 <dirlink+0x86>
      panic("dirlink read");
    80003f44:	00004517          	auipc	a0,0x4
    80003f48:	6f450513          	addi	a0,a0,1780 # 80008638 <syscalls+0x1e0>
    80003f4c:	ffffc097          	auipc	ra,0xffffc
    80003f50:	5f4080e7          	jalr	1524(ra) # 80000540 <panic>

0000000080003f54 <namei>:

struct inode*
namei(char *path)
{
    80003f54:	1101                	addi	sp,sp,-32
    80003f56:	ec06                	sd	ra,24(sp)
    80003f58:	e822                	sd	s0,16(sp)
    80003f5a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f5c:	fe040613          	addi	a2,s0,-32
    80003f60:	4581                	li	a1,0
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	dda080e7          	jalr	-550(ra) # 80003d3c <namex>
}
    80003f6a:	60e2                	ld	ra,24(sp)
    80003f6c:	6442                	ld	s0,16(sp)
    80003f6e:	6105                	addi	sp,sp,32
    80003f70:	8082                	ret

0000000080003f72 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f72:	1141                	addi	sp,sp,-16
    80003f74:	e406                	sd	ra,8(sp)
    80003f76:	e022                	sd	s0,0(sp)
    80003f78:	0800                	addi	s0,sp,16
    80003f7a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f7c:	4585                	li	a1,1
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	dbe080e7          	jalr	-578(ra) # 80003d3c <namex>
}
    80003f86:	60a2                	ld	ra,8(sp)
    80003f88:	6402                	ld	s0,0(sp)
    80003f8a:	0141                	addi	sp,sp,16
    80003f8c:	8082                	ret

0000000080003f8e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f8e:	1101                	addi	sp,sp,-32
    80003f90:	ec06                	sd	ra,24(sp)
    80003f92:	e822                	sd	s0,16(sp)
    80003f94:	e426                	sd	s1,8(sp)
    80003f96:	e04a                	sd	s2,0(sp)
    80003f98:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f9a:	00035917          	auipc	s2,0x35
    80003f9e:	da690913          	addi	s2,s2,-602 # 80038d40 <log>
    80003fa2:	01892583          	lw	a1,24(s2)
    80003fa6:	02892503          	lw	a0,40(s2)
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	fe6080e7          	jalr	-26(ra) # 80002f90 <bread>
    80003fb2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fb4:	02c92683          	lw	a3,44(s2)
    80003fb8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fba:	02d05863          	blez	a3,80003fea <write_head+0x5c>
    80003fbe:	00035797          	auipc	a5,0x35
    80003fc2:	db278793          	addi	a5,a5,-590 # 80038d70 <log+0x30>
    80003fc6:	05c50713          	addi	a4,a0,92
    80003fca:	36fd                	addiw	a3,a3,-1
    80003fcc:	02069613          	slli	a2,a3,0x20
    80003fd0:	01e65693          	srli	a3,a2,0x1e
    80003fd4:	00035617          	auipc	a2,0x35
    80003fd8:	da060613          	addi	a2,a2,-608 # 80038d74 <log+0x34>
    80003fdc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fde:	4390                	lw	a2,0(a5)
    80003fe0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe2:	0791                	addi	a5,a5,4
    80003fe4:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fe6:	fed79ce3          	bne	a5,a3,80003fde <write_head+0x50>
  }
  bwrite(buf);
    80003fea:	8526                	mv	a0,s1
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	096080e7          	jalr	150(ra) # 80003082 <bwrite>
  brelse(buf);
    80003ff4:	8526                	mv	a0,s1
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	0ca080e7          	jalr	202(ra) # 800030c0 <brelse>
}
    80003ffe:	60e2                	ld	ra,24(sp)
    80004000:	6442                	ld	s0,16(sp)
    80004002:	64a2                	ld	s1,8(sp)
    80004004:	6902                	ld	s2,0(sp)
    80004006:	6105                	addi	sp,sp,32
    80004008:	8082                	ret

000000008000400a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000400a:	00035797          	auipc	a5,0x35
    8000400e:	d627a783          	lw	a5,-670(a5) # 80038d6c <log+0x2c>
    80004012:	0af05d63          	blez	a5,800040cc <install_trans+0xc2>
{
    80004016:	7139                	addi	sp,sp,-64
    80004018:	fc06                	sd	ra,56(sp)
    8000401a:	f822                	sd	s0,48(sp)
    8000401c:	f426                	sd	s1,40(sp)
    8000401e:	f04a                	sd	s2,32(sp)
    80004020:	ec4e                	sd	s3,24(sp)
    80004022:	e852                	sd	s4,16(sp)
    80004024:	e456                	sd	s5,8(sp)
    80004026:	e05a                	sd	s6,0(sp)
    80004028:	0080                	addi	s0,sp,64
    8000402a:	8b2a                	mv	s6,a0
    8000402c:	00035a97          	auipc	s5,0x35
    80004030:	d44a8a93          	addi	s5,s5,-700 # 80038d70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004034:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004036:	00035997          	auipc	s3,0x35
    8000403a:	d0a98993          	addi	s3,s3,-758 # 80038d40 <log>
    8000403e:	a00d                	j	80004060 <install_trans+0x56>
    brelse(lbuf);
    80004040:	854a                	mv	a0,s2
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	07e080e7          	jalr	126(ra) # 800030c0 <brelse>
    brelse(dbuf);
    8000404a:	8526                	mv	a0,s1
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	074080e7          	jalr	116(ra) # 800030c0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004054:	2a05                	addiw	s4,s4,1
    80004056:	0a91                	addi	s5,s5,4
    80004058:	02c9a783          	lw	a5,44(s3)
    8000405c:	04fa5e63          	bge	s4,a5,800040b8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004060:	0189a583          	lw	a1,24(s3)
    80004064:	014585bb          	addw	a1,a1,s4
    80004068:	2585                	addiw	a1,a1,1
    8000406a:	0289a503          	lw	a0,40(s3)
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	f22080e7          	jalr	-222(ra) # 80002f90 <bread>
    80004076:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004078:	000aa583          	lw	a1,0(s5)
    8000407c:	0289a503          	lw	a0,40(s3)
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	f10080e7          	jalr	-240(ra) # 80002f90 <bread>
    80004088:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000408a:	40000613          	li	a2,1024
    8000408e:	05890593          	addi	a1,s2,88
    80004092:	05850513          	addi	a0,a0,88
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	c98080e7          	jalr	-872(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000409e:	8526                	mv	a0,s1
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	fe2080e7          	jalr	-30(ra) # 80003082 <bwrite>
    if(recovering == 0)
    800040a8:	f80b1ce3          	bnez	s6,80004040 <install_trans+0x36>
      bunpin(dbuf);
    800040ac:	8526                	mv	a0,s1
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	0ec080e7          	jalr	236(ra) # 8000319a <bunpin>
    800040b6:	b769                	j	80004040 <install_trans+0x36>
}
    800040b8:	70e2                	ld	ra,56(sp)
    800040ba:	7442                	ld	s0,48(sp)
    800040bc:	74a2                	ld	s1,40(sp)
    800040be:	7902                	ld	s2,32(sp)
    800040c0:	69e2                	ld	s3,24(sp)
    800040c2:	6a42                	ld	s4,16(sp)
    800040c4:	6aa2                	ld	s5,8(sp)
    800040c6:	6b02                	ld	s6,0(sp)
    800040c8:	6121                	addi	sp,sp,64
    800040ca:	8082                	ret
    800040cc:	8082                	ret

00000000800040ce <initlog>:
{
    800040ce:	7179                	addi	sp,sp,-48
    800040d0:	f406                	sd	ra,40(sp)
    800040d2:	f022                	sd	s0,32(sp)
    800040d4:	ec26                	sd	s1,24(sp)
    800040d6:	e84a                	sd	s2,16(sp)
    800040d8:	e44e                	sd	s3,8(sp)
    800040da:	1800                	addi	s0,sp,48
    800040dc:	892a                	mv	s2,a0
    800040de:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040e0:	00035497          	auipc	s1,0x35
    800040e4:	c6048493          	addi	s1,s1,-928 # 80038d40 <log>
    800040e8:	00004597          	auipc	a1,0x4
    800040ec:	56058593          	addi	a1,a1,1376 # 80008648 <syscalls+0x1f0>
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	a54080e7          	jalr	-1452(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800040fa:	0149a583          	lw	a1,20(s3)
    800040fe:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004100:	0109a783          	lw	a5,16(s3)
    80004104:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004106:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000410a:	854a                	mv	a0,s2
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	e84080e7          	jalr	-380(ra) # 80002f90 <bread>
  log.lh.n = lh->n;
    80004114:	4d34                	lw	a3,88(a0)
    80004116:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004118:	02d05663          	blez	a3,80004144 <initlog+0x76>
    8000411c:	05c50793          	addi	a5,a0,92
    80004120:	00035717          	auipc	a4,0x35
    80004124:	c5070713          	addi	a4,a4,-944 # 80038d70 <log+0x30>
    80004128:	36fd                	addiw	a3,a3,-1
    8000412a:	02069613          	slli	a2,a3,0x20
    8000412e:	01e65693          	srli	a3,a2,0x1e
    80004132:	06050613          	addi	a2,a0,96
    80004136:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004138:	4390                	lw	a2,0(a5)
    8000413a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000413c:	0791                	addi	a5,a5,4
    8000413e:	0711                	addi	a4,a4,4
    80004140:	fed79ce3          	bne	a5,a3,80004138 <initlog+0x6a>
  brelse(buf);
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	f7c080e7          	jalr	-132(ra) # 800030c0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000414c:	4505                	li	a0,1
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	ebc080e7          	jalr	-324(ra) # 8000400a <install_trans>
  log.lh.n = 0;
    80004156:	00035797          	auipc	a5,0x35
    8000415a:	c007ab23          	sw	zero,-1002(a5) # 80038d6c <log+0x2c>
  write_head(); // clear the log
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	e30080e7          	jalr	-464(ra) # 80003f8e <write_head>
}
    80004166:	70a2                	ld	ra,40(sp)
    80004168:	7402                	ld	s0,32(sp)
    8000416a:	64e2                	ld	s1,24(sp)
    8000416c:	6942                	ld	s2,16(sp)
    8000416e:	69a2                	ld	s3,8(sp)
    80004170:	6145                	addi	sp,sp,48
    80004172:	8082                	ret

0000000080004174 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004174:	1101                	addi	sp,sp,-32
    80004176:	ec06                	sd	ra,24(sp)
    80004178:	e822                	sd	s0,16(sp)
    8000417a:	e426                	sd	s1,8(sp)
    8000417c:	e04a                	sd	s2,0(sp)
    8000417e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004180:	00035517          	auipc	a0,0x35
    80004184:	bc050513          	addi	a0,a0,-1088 # 80038d40 <log>
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	a4e080e7          	jalr	-1458(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004190:	00035497          	auipc	s1,0x35
    80004194:	bb048493          	addi	s1,s1,-1104 # 80038d40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004198:	4979                	li	s2,30
    8000419a:	a039                	j	800041a8 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000419c:	85a6                	mv	a1,s1
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffe097          	auipc	ra,0xffffe
    800041a4:	eb4080e7          	jalr	-332(ra) # 80002054 <sleep>
    if(log.committing){
    800041a8:	50dc                	lw	a5,36(s1)
    800041aa:	fbed                	bnez	a5,8000419c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ac:	5098                	lw	a4,32(s1)
    800041ae:	2705                	addiw	a4,a4,1
    800041b0:	0007069b          	sext.w	a3,a4
    800041b4:	0027179b          	slliw	a5,a4,0x2
    800041b8:	9fb9                	addw	a5,a5,a4
    800041ba:	0017979b          	slliw	a5,a5,0x1
    800041be:	54d8                	lw	a4,44(s1)
    800041c0:	9fb9                	addw	a5,a5,a4
    800041c2:	00f95963          	bge	s2,a5,800041d4 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041c6:	85a6                	mv	a1,s1
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffe097          	auipc	ra,0xffffe
    800041ce:	e8a080e7          	jalr	-374(ra) # 80002054 <sleep>
    800041d2:	bfd9                	j	800041a8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041d4:	00035517          	auipc	a0,0x35
    800041d8:	b6c50513          	addi	a0,a0,-1172 # 80038d40 <log>
    800041dc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	aac080e7          	jalr	-1364(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041e6:	60e2                	ld	ra,24(sp)
    800041e8:	6442                	ld	s0,16(sp)
    800041ea:	64a2                	ld	s1,8(sp)
    800041ec:	6902                	ld	s2,0(sp)
    800041ee:	6105                	addi	sp,sp,32
    800041f0:	8082                	ret

00000000800041f2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f2:	7139                	addi	sp,sp,-64
    800041f4:	fc06                	sd	ra,56(sp)
    800041f6:	f822                	sd	s0,48(sp)
    800041f8:	f426                	sd	s1,40(sp)
    800041fa:	f04a                	sd	s2,32(sp)
    800041fc:	ec4e                	sd	s3,24(sp)
    800041fe:	e852                	sd	s4,16(sp)
    80004200:	e456                	sd	s5,8(sp)
    80004202:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004204:	00035497          	auipc	s1,0x35
    80004208:	b3c48493          	addi	s1,s1,-1220 # 80038d40 <log>
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	9c8080e7          	jalr	-1592(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004216:	509c                	lw	a5,32(s1)
    80004218:	37fd                	addiw	a5,a5,-1
    8000421a:	0007891b          	sext.w	s2,a5
    8000421e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004220:	50dc                	lw	a5,36(s1)
    80004222:	e7b9                	bnez	a5,80004270 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004224:	04091e63          	bnez	s2,80004280 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004228:	00035497          	auipc	s1,0x35
    8000422c:	b1848493          	addi	s1,s1,-1256 # 80038d40 <log>
    80004230:	4785                	li	a5,1
    80004232:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004234:	8526                	mv	a0,s1
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	a54080e7          	jalr	-1452(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000423e:	54dc                	lw	a5,44(s1)
    80004240:	06f04763          	bgtz	a5,800042ae <end_op+0xbc>
    acquire(&log.lock);
    80004244:	00035497          	auipc	s1,0x35
    80004248:	afc48493          	addi	s1,s1,-1284 # 80038d40 <log>
    8000424c:	8526                	mv	a0,s1
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	988080e7          	jalr	-1656(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004256:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffe097          	auipc	ra,0xffffe
    80004260:	e5c080e7          	jalr	-420(ra) # 800020b8 <wakeup>
    release(&log.lock);
    80004264:	8526                	mv	a0,s1
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	a24080e7          	jalr	-1500(ra) # 80000c8a <release>
}
    8000426e:	a03d                	j	8000429c <end_op+0xaa>
    panic("log.committing");
    80004270:	00004517          	auipc	a0,0x4
    80004274:	3e050513          	addi	a0,a0,992 # 80008650 <syscalls+0x1f8>
    80004278:	ffffc097          	auipc	ra,0xffffc
    8000427c:	2c8080e7          	jalr	712(ra) # 80000540 <panic>
    wakeup(&log);
    80004280:	00035497          	auipc	s1,0x35
    80004284:	ac048493          	addi	s1,s1,-1344 # 80038d40 <log>
    80004288:	8526                	mv	a0,s1
    8000428a:	ffffe097          	auipc	ra,0xffffe
    8000428e:	e2e080e7          	jalr	-466(ra) # 800020b8 <wakeup>
  release(&log.lock);
    80004292:	8526                	mv	a0,s1
    80004294:	ffffd097          	auipc	ra,0xffffd
    80004298:	9f6080e7          	jalr	-1546(ra) # 80000c8a <release>
}
    8000429c:	70e2                	ld	ra,56(sp)
    8000429e:	7442                	ld	s0,48(sp)
    800042a0:	74a2                	ld	s1,40(sp)
    800042a2:	7902                	ld	s2,32(sp)
    800042a4:	69e2                	ld	s3,24(sp)
    800042a6:	6a42                	ld	s4,16(sp)
    800042a8:	6aa2                	ld	s5,8(sp)
    800042aa:	6121                	addi	sp,sp,64
    800042ac:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ae:	00035a97          	auipc	s5,0x35
    800042b2:	ac2a8a93          	addi	s5,s5,-1342 # 80038d70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042b6:	00035a17          	auipc	s4,0x35
    800042ba:	a8aa0a13          	addi	s4,s4,-1398 # 80038d40 <log>
    800042be:	018a2583          	lw	a1,24(s4)
    800042c2:	012585bb          	addw	a1,a1,s2
    800042c6:	2585                	addiw	a1,a1,1
    800042c8:	028a2503          	lw	a0,40(s4)
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	cc4080e7          	jalr	-828(ra) # 80002f90 <bread>
    800042d4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042d6:	000aa583          	lw	a1,0(s5)
    800042da:	028a2503          	lw	a0,40(s4)
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	cb2080e7          	jalr	-846(ra) # 80002f90 <bread>
    800042e6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042e8:	40000613          	li	a2,1024
    800042ec:	05850593          	addi	a1,a0,88
    800042f0:	05848513          	addi	a0,s1,88
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	a3a080e7          	jalr	-1478(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	d84080e7          	jalr	-636(ra) # 80003082 <bwrite>
    brelse(from);
    80004306:	854e                	mv	a0,s3
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	db8080e7          	jalr	-584(ra) # 800030c0 <brelse>
    brelse(to);
    80004310:	8526                	mv	a0,s1
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	dae080e7          	jalr	-594(ra) # 800030c0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431a:	2905                	addiw	s2,s2,1
    8000431c:	0a91                	addi	s5,s5,4
    8000431e:	02ca2783          	lw	a5,44(s4)
    80004322:	f8f94ee3          	blt	s2,a5,800042be <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	c68080e7          	jalr	-920(ra) # 80003f8e <write_head>
    install_trans(0); // Now install writes to home locations
    8000432e:	4501                	li	a0,0
    80004330:	00000097          	auipc	ra,0x0
    80004334:	cda080e7          	jalr	-806(ra) # 8000400a <install_trans>
    log.lh.n = 0;
    80004338:	00035797          	auipc	a5,0x35
    8000433c:	a207aa23          	sw	zero,-1484(a5) # 80038d6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004340:	00000097          	auipc	ra,0x0
    80004344:	c4e080e7          	jalr	-946(ra) # 80003f8e <write_head>
    80004348:	bdf5                	j	80004244 <end_op+0x52>

000000008000434a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000434a:	1101                	addi	sp,sp,-32
    8000434c:	ec06                	sd	ra,24(sp)
    8000434e:	e822                	sd	s0,16(sp)
    80004350:	e426                	sd	s1,8(sp)
    80004352:	e04a                	sd	s2,0(sp)
    80004354:	1000                	addi	s0,sp,32
    80004356:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004358:	00035917          	auipc	s2,0x35
    8000435c:	9e890913          	addi	s2,s2,-1560 # 80038d40 <log>
    80004360:	854a                	mv	a0,s2
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	874080e7          	jalr	-1932(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000436a:	02c92603          	lw	a2,44(s2)
    8000436e:	47f5                	li	a5,29
    80004370:	06c7c563          	blt	a5,a2,800043da <log_write+0x90>
    80004374:	00035797          	auipc	a5,0x35
    80004378:	9e87a783          	lw	a5,-1560(a5) # 80038d5c <log+0x1c>
    8000437c:	37fd                	addiw	a5,a5,-1
    8000437e:	04f65e63          	bge	a2,a5,800043da <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004382:	00035797          	auipc	a5,0x35
    80004386:	9de7a783          	lw	a5,-1570(a5) # 80038d60 <log+0x20>
    8000438a:	06f05063          	blez	a5,800043ea <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000438e:	4781                	li	a5,0
    80004390:	06c05563          	blez	a2,800043fa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004394:	44cc                	lw	a1,12(s1)
    80004396:	00035717          	auipc	a4,0x35
    8000439a:	9da70713          	addi	a4,a4,-1574 # 80038d70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000439e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a0:	4314                	lw	a3,0(a4)
    800043a2:	04b68c63          	beq	a3,a1,800043fa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043a6:	2785                	addiw	a5,a5,1
    800043a8:	0711                	addi	a4,a4,4
    800043aa:	fef61be3          	bne	a2,a5,800043a0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ae:	0621                	addi	a2,a2,8
    800043b0:	060a                	slli	a2,a2,0x2
    800043b2:	00035797          	auipc	a5,0x35
    800043b6:	98e78793          	addi	a5,a5,-1650 # 80038d40 <log>
    800043ba:	97b2                	add	a5,a5,a2
    800043bc:	44d8                	lw	a4,12(s1)
    800043be:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	d9c080e7          	jalr	-612(ra) # 8000315e <bpin>
    log.lh.n++;
    800043ca:	00035717          	auipc	a4,0x35
    800043ce:	97670713          	addi	a4,a4,-1674 # 80038d40 <log>
    800043d2:	575c                	lw	a5,44(a4)
    800043d4:	2785                	addiw	a5,a5,1
    800043d6:	d75c                	sw	a5,44(a4)
    800043d8:	a82d                	j	80004412 <log_write+0xc8>
    panic("too big a transaction");
    800043da:	00004517          	auipc	a0,0x4
    800043de:	28650513          	addi	a0,a0,646 # 80008660 <syscalls+0x208>
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	15e080e7          	jalr	350(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800043ea:	00004517          	auipc	a0,0x4
    800043ee:	28e50513          	addi	a0,a0,654 # 80008678 <syscalls+0x220>
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	14e080e7          	jalr	334(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800043fa:	00878693          	addi	a3,a5,8
    800043fe:	068a                	slli	a3,a3,0x2
    80004400:	00035717          	auipc	a4,0x35
    80004404:	94070713          	addi	a4,a4,-1728 # 80038d40 <log>
    80004408:	9736                	add	a4,a4,a3
    8000440a:	44d4                	lw	a3,12(s1)
    8000440c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000440e:	faf609e3          	beq	a2,a5,800043c0 <log_write+0x76>
  }
  release(&log.lock);
    80004412:	00035517          	auipc	a0,0x35
    80004416:	92e50513          	addi	a0,a0,-1746 # 80038d40 <log>
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	870080e7          	jalr	-1936(ra) # 80000c8a <release>
}
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6902                	ld	s2,0(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret

000000008000442e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000442e:	1101                	addi	sp,sp,-32
    80004430:	ec06                	sd	ra,24(sp)
    80004432:	e822                	sd	s0,16(sp)
    80004434:	e426                	sd	s1,8(sp)
    80004436:	e04a                	sd	s2,0(sp)
    80004438:	1000                	addi	s0,sp,32
    8000443a:	84aa                	mv	s1,a0
    8000443c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000443e:	00004597          	auipc	a1,0x4
    80004442:	25a58593          	addi	a1,a1,602 # 80008698 <syscalls+0x240>
    80004446:	0521                	addi	a0,a0,8
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	6fe080e7          	jalr	1790(ra) # 80000b46 <initlock>
  lk->name = name;
    80004450:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004454:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004458:	0204a423          	sw	zero,40(s1)
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	addi	sp,sp,32
    80004466:	8082                	ret

0000000080004468 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004468:	1101                	addi	sp,sp,-32
    8000446a:	ec06                	sd	ra,24(sp)
    8000446c:	e822                	sd	s0,16(sp)
    8000446e:	e426                	sd	s1,8(sp)
    80004470:	e04a                	sd	s2,0(sp)
    80004472:	1000                	addi	s0,sp,32
    80004474:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004476:	00850913          	addi	s2,a0,8
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	75a080e7          	jalr	1882(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004484:	409c                	lw	a5,0(s1)
    80004486:	cb89                	beqz	a5,80004498 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004488:	85ca                	mv	a1,s2
    8000448a:	8526                	mv	a0,s1
    8000448c:	ffffe097          	auipc	ra,0xffffe
    80004490:	bc8080e7          	jalr	-1080(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004494:	409c                	lw	a5,0(s1)
    80004496:	fbed                	bnez	a5,80004488 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004498:	4785                	li	a5,1
    8000449a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	510080e7          	jalr	1296(ra) # 800019ac <myproc>
    800044a4:	591c                	lw	a5,48(a0)
    800044a6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044a8:	854a                	mv	a0,s2
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	7e0080e7          	jalr	2016(ra) # 80000c8a <release>
}
    800044b2:	60e2                	ld	ra,24(sp)
    800044b4:	6442                	ld	s0,16(sp)
    800044b6:	64a2                	ld	s1,8(sp)
    800044b8:	6902                	ld	s2,0(sp)
    800044ba:	6105                	addi	sp,sp,32
    800044bc:	8082                	ret

00000000800044be <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	e04a                	sd	s2,0(sp)
    800044c8:	1000                	addi	s0,sp,32
    800044ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044cc:	00850913          	addi	s2,a0,8
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	704080e7          	jalr	1796(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044e2:	8526                	mv	a0,s1
    800044e4:	ffffe097          	auipc	ra,0xffffe
    800044e8:	bd4080e7          	jalr	-1068(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    800044ec:	854a                	mv	a0,s2
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	79c080e7          	jalr	1948(ra) # 80000c8a <release>
}
    800044f6:	60e2                	ld	ra,24(sp)
    800044f8:	6442                	ld	s0,16(sp)
    800044fa:	64a2                	ld	s1,8(sp)
    800044fc:	6902                	ld	s2,0(sp)
    800044fe:	6105                	addi	sp,sp,32
    80004500:	8082                	ret

0000000080004502 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004502:	7179                	addi	sp,sp,-48
    80004504:	f406                	sd	ra,40(sp)
    80004506:	f022                	sd	s0,32(sp)
    80004508:	ec26                	sd	s1,24(sp)
    8000450a:	e84a                	sd	s2,16(sp)
    8000450c:	e44e                	sd	s3,8(sp)
    8000450e:	1800                	addi	s0,sp,48
    80004510:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004512:	00850913          	addi	s2,a0,8
    80004516:	854a                	mv	a0,s2
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	6be080e7          	jalr	1726(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004520:	409c                	lw	a5,0(s1)
    80004522:	ef99                	bnez	a5,80004540 <holdingsleep+0x3e>
    80004524:	4481                	li	s1,0
  release(&lk->lk);
    80004526:	854a                	mv	a0,s2
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	762080e7          	jalr	1890(ra) # 80000c8a <release>
  return r;
}
    80004530:	8526                	mv	a0,s1
    80004532:	70a2                	ld	ra,40(sp)
    80004534:	7402                	ld	s0,32(sp)
    80004536:	64e2                	ld	s1,24(sp)
    80004538:	6942                	ld	s2,16(sp)
    8000453a:	69a2                	ld	s3,8(sp)
    8000453c:	6145                	addi	sp,sp,48
    8000453e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004540:	0284a983          	lw	s3,40(s1)
    80004544:	ffffd097          	auipc	ra,0xffffd
    80004548:	468080e7          	jalr	1128(ra) # 800019ac <myproc>
    8000454c:	5904                	lw	s1,48(a0)
    8000454e:	413484b3          	sub	s1,s1,s3
    80004552:	0014b493          	seqz	s1,s1
    80004556:	bfc1                	j	80004526 <holdingsleep+0x24>

0000000080004558 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004558:	1141                	addi	sp,sp,-16
    8000455a:	e406                	sd	ra,8(sp)
    8000455c:	e022                	sd	s0,0(sp)
    8000455e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004560:	00004597          	auipc	a1,0x4
    80004564:	14858593          	addi	a1,a1,328 # 800086a8 <syscalls+0x250>
    80004568:	00035517          	auipc	a0,0x35
    8000456c:	92050513          	addi	a0,a0,-1760 # 80038e88 <ftable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	5d6080e7          	jalr	1494(ra) # 80000b46 <initlock>
}
    80004578:	60a2                	ld	ra,8(sp)
    8000457a:	6402                	ld	s0,0(sp)
    8000457c:	0141                	addi	sp,sp,16
    8000457e:	8082                	ret

0000000080004580 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004580:	1101                	addi	sp,sp,-32
    80004582:	ec06                	sd	ra,24(sp)
    80004584:	e822                	sd	s0,16(sp)
    80004586:	e426                	sd	s1,8(sp)
    80004588:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000458a:	00035517          	auipc	a0,0x35
    8000458e:	8fe50513          	addi	a0,a0,-1794 # 80038e88 <ftable>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	644080e7          	jalr	1604(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000459a:	00035497          	auipc	s1,0x35
    8000459e:	90648493          	addi	s1,s1,-1786 # 80038ea0 <ftable+0x18>
    800045a2:	00036717          	auipc	a4,0x36
    800045a6:	89e70713          	addi	a4,a4,-1890 # 80039e40 <disk>
    if(f->ref == 0){
    800045aa:	40dc                	lw	a5,4(s1)
    800045ac:	cf99                	beqz	a5,800045ca <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ae:	02848493          	addi	s1,s1,40
    800045b2:	fee49ce3          	bne	s1,a4,800045aa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045b6:	00035517          	auipc	a0,0x35
    800045ba:	8d250513          	addi	a0,a0,-1838 # 80038e88 <ftable>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	6cc080e7          	jalr	1740(ra) # 80000c8a <release>
  return 0;
    800045c6:	4481                	li	s1,0
    800045c8:	a819                	j	800045de <filealloc+0x5e>
      f->ref = 1;
    800045ca:	4785                	li	a5,1
    800045cc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ce:	00035517          	auipc	a0,0x35
    800045d2:	8ba50513          	addi	a0,a0,-1862 # 80038e88 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6b4080e7          	jalr	1716(ra) # 80000c8a <release>
}
    800045de:	8526                	mv	a0,s1
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret

00000000800045ea <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ea:	1101                	addi	sp,sp,-32
    800045ec:	ec06                	sd	ra,24(sp)
    800045ee:	e822                	sd	s0,16(sp)
    800045f0:	e426                	sd	s1,8(sp)
    800045f2:	1000                	addi	s0,sp,32
    800045f4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045f6:	00035517          	auipc	a0,0x35
    800045fa:	89250513          	addi	a0,a0,-1902 # 80038e88 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	5d8080e7          	jalr	1496(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004606:	40dc                	lw	a5,4(s1)
    80004608:	02f05263          	blez	a5,8000462c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000460c:	2785                	addiw	a5,a5,1
    8000460e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004610:	00035517          	auipc	a0,0x35
    80004614:	87850513          	addi	a0,a0,-1928 # 80038e88 <ftable>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	672080e7          	jalr	1650(ra) # 80000c8a <release>
  return f;
}
    80004620:	8526                	mv	a0,s1
    80004622:	60e2                	ld	ra,24(sp)
    80004624:	6442                	ld	s0,16(sp)
    80004626:	64a2                	ld	s1,8(sp)
    80004628:	6105                	addi	sp,sp,32
    8000462a:	8082                	ret
    panic("filedup");
    8000462c:	00004517          	auipc	a0,0x4
    80004630:	08450513          	addi	a0,a0,132 # 800086b0 <syscalls+0x258>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	f0c080e7          	jalr	-244(ra) # 80000540 <panic>

000000008000463c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000463c:	7139                	addi	sp,sp,-64
    8000463e:	fc06                	sd	ra,56(sp)
    80004640:	f822                	sd	s0,48(sp)
    80004642:	f426                	sd	s1,40(sp)
    80004644:	f04a                	sd	s2,32(sp)
    80004646:	ec4e                	sd	s3,24(sp)
    80004648:	e852                	sd	s4,16(sp)
    8000464a:	e456                	sd	s5,8(sp)
    8000464c:	0080                	addi	s0,sp,64
    8000464e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004650:	00035517          	auipc	a0,0x35
    80004654:	83850513          	addi	a0,a0,-1992 # 80038e88 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	57e080e7          	jalr	1406(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004660:	40dc                	lw	a5,4(s1)
    80004662:	06f05163          	blez	a5,800046c4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004666:	37fd                	addiw	a5,a5,-1
    80004668:	0007871b          	sext.w	a4,a5
    8000466c:	c0dc                	sw	a5,4(s1)
    8000466e:	06e04363          	bgtz	a4,800046d4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004672:	0004a903          	lw	s2,0(s1)
    80004676:	0094ca83          	lbu	s5,9(s1)
    8000467a:	0104ba03          	ld	s4,16(s1)
    8000467e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004682:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004686:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000468a:	00034517          	auipc	a0,0x34
    8000468e:	7fe50513          	addi	a0,a0,2046 # 80038e88 <ftable>
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	5f8080e7          	jalr	1528(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000469a:	4785                	li	a5,1
    8000469c:	04f90d63          	beq	s2,a5,800046f6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046a0:	3979                	addiw	s2,s2,-2
    800046a2:	4785                	li	a5,1
    800046a4:	0527e063          	bltu	a5,s2,800046e4 <fileclose+0xa8>
    begin_op();
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	acc080e7          	jalr	-1332(ra) # 80004174 <begin_op>
    iput(ff.ip);
    800046b0:	854e                	mv	a0,s3
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	2b0080e7          	jalr	688(ra) # 80003962 <iput>
    end_op();
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	b38080e7          	jalr	-1224(ra) # 800041f2 <end_op>
    800046c2:	a00d                	j	800046e4 <fileclose+0xa8>
    panic("fileclose");
    800046c4:	00004517          	auipc	a0,0x4
    800046c8:	ff450513          	addi	a0,a0,-12 # 800086b8 <syscalls+0x260>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	e74080e7          	jalr	-396(ra) # 80000540 <panic>
    release(&ftable.lock);
    800046d4:	00034517          	auipc	a0,0x34
    800046d8:	7b450513          	addi	a0,a0,1972 # 80038e88 <ftable>
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	5ae080e7          	jalr	1454(ra) # 80000c8a <release>
  }
}
    800046e4:	70e2                	ld	ra,56(sp)
    800046e6:	7442                	ld	s0,48(sp)
    800046e8:	74a2                	ld	s1,40(sp)
    800046ea:	7902                	ld	s2,32(sp)
    800046ec:	69e2                	ld	s3,24(sp)
    800046ee:	6a42                	ld	s4,16(sp)
    800046f0:	6aa2                	ld	s5,8(sp)
    800046f2:	6121                	addi	sp,sp,64
    800046f4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046f6:	85d6                	mv	a1,s5
    800046f8:	8552                	mv	a0,s4
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	34c080e7          	jalr	844(ra) # 80004a46 <pipeclose>
    80004702:	b7cd                	j	800046e4 <fileclose+0xa8>

0000000080004704 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004704:	715d                	addi	sp,sp,-80
    80004706:	e486                	sd	ra,72(sp)
    80004708:	e0a2                	sd	s0,64(sp)
    8000470a:	fc26                	sd	s1,56(sp)
    8000470c:	f84a                	sd	s2,48(sp)
    8000470e:	f44e                	sd	s3,40(sp)
    80004710:	0880                	addi	s0,sp,80
    80004712:	84aa                	mv	s1,a0
    80004714:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004716:	ffffd097          	auipc	ra,0xffffd
    8000471a:	296080e7          	jalr	662(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000471e:	409c                	lw	a5,0(s1)
    80004720:	37f9                	addiw	a5,a5,-2
    80004722:	4705                	li	a4,1
    80004724:	04f76763          	bltu	a4,a5,80004772 <filestat+0x6e>
    80004728:	892a                	mv	s2,a0
    ilock(f->ip);
    8000472a:	6c88                	ld	a0,24(s1)
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	07c080e7          	jalr	124(ra) # 800037a8 <ilock>
    stati(f->ip, &st);
    80004734:	fb840593          	addi	a1,s0,-72
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	2f8080e7          	jalr	760(ra) # 80003a32 <stati>
    iunlock(f->ip);
    80004742:	6c88                	ld	a0,24(s1)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	126080e7          	jalr	294(ra) # 8000386a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000474c:	46e1                	li	a3,24
    8000474e:	fb840613          	addi	a2,s0,-72
    80004752:	85ce                	mv	a1,s3
    80004754:	05093503          	ld	a0,80(s2)
    80004758:	ffffd097          	auipc	ra,0xffffd
    8000475c:	f14080e7          	jalr	-236(ra) # 8000166c <copyout>
    80004760:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004764:	60a6                	ld	ra,72(sp)
    80004766:	6406                	ld	s0,64(sp)
    80004768:	74e2                	ld	s1,56(sp)
    8000476a:	7942                	ld	s2,48(sp)
    8000476c:	79a2                	ld	s3,40(sp)
    8000476e:	6161                	addi	sp,sp,80
    80004770:	8082                	ret
  return -1;
    80004772:	557d                	li	a0,-1
    80004774:	bfc5                	j	80004764 <filestat+0x60>

0000000080004776 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004776:	7179                	addi	sp,sp,-48
    80004778:	f406                	sd	ra,40(sp)
    8000477a:	f022                	sd	s0,32(sp)
    8000477c:	ec26                	sd	s1,24(sp)
    8000477e:	e84a                	sd	s2,16(sp)
    80004780:	e44e                	sd	s3,8(sp)
    80004782:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004784:	00854783          	lbu	a5,8(a0)
    80004788:	c3d5                	beqz	a5,8000482c <fileread+0xb6>
    8000478a:	84aa                	mv	s1,a0
    8000478c:	89ae                	mv	s3,a1
    8000478e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004790:	411c                	lw	a5,0(a0)
    80004792:	4705                	li	a4,1
    80004794:	04e78963          	beq	a5,a4,800047e6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004798:	470d                	li	a4,3
    8000479a:	04e78d63          	beq	a5,a4,800047f4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000479e:	4709                	li	a4,2
    800047a0:	06e79e63          	bne	a5,a4,8000481c <fileread+0xa6>
    ilock(f->ip);
    800047a4:	6d08                	ld	a0,24(a0)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	002080e7          	jalr	2(ra) # 800037a8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ae:	874a                	mv	a4,s2
    800047b0:	5094                	lw	a3,32(s1)
    800047b2:	864e                	mv	a2,s3
    800047b4:	4585                	li	a1,1
    800047b6:	6c88                	ld	a0,24(s1)
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	2a4080e7          	jalr	676(ra) # 80003a5c <readi>
    800047c0:	892a                	mv	s2,a0
    800047c2:	00a05563          	blez	a0,800047cc <fileread+0x56>
      f->off += r;
    800047c6:	509c                	lw	a5,32(s1)
    800047c8:	9fa9                	addw	a5,a5,a0
    800047ca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047cc:	6c88                	ld	a0,24(s1)
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	09c080e7          	jalr	156(ra) # 8000386a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047d6:	854a                	mv	a0,s2
    800047d8:	70a2                	ld	ra,40(sp)
    800047da:	7402                	ld	s0,32(sp)
    800047dc:	64e2                	ld	s1,24(sp)
    800047de:	6942                	ld	s2,16(sp)
    800047e0:	69a2                	ld	s3,8(sp)
    800047e2:	6145                	addi	sp,sp,48
    800047e4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047e6:	6908                	ld	a0,16(a0)
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	3c6080e7          	jalr	966(ra) # 80004bae <piperead>
    800047f0:	892a                	mv	s2,a0
    800047f2:	b7d5                	j	800047d6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047f4:	02451783          	lh	a5,36(a0)
    800047f8:	03079693          	slli	a3,a5,0x30
    800047fc:	92c1                	srli	a3,a3,0x30
    800047fe:	4725                	li	a4,9
    80004800:	02d76863          	bltu	a4,a3,80004830 <fileread+0xba>
    80004804:	0792                	slli	a5,a5,0x4
    80004806:	00034717          	auipc	a4,0x34
    8000480a:	5e270713          	addi	a4,a4,1506 # 80038de8 <devsw>
    8000480e:	97ba                	add	a5,a5,a4
    80004810:	639c                	ld	a5,0(a5)
    80004812:	c38d                	beqz	a5,80004834 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004814:	4505                	li	a0,1
    80004816:	9782                	jalr	a5
    80004818:	892a                	mv	s2,a0
    8000481a:	bf75                	j	800047d6 <fileread+0x60>
    panic("fileread");
    8000481c:	00004517          	auipc	a0,0x4
    80004820:	eac50513          	addi	a0,a0,-340 # 800086c8 <syscalls+0x270>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	d1c080e7          	jalr	-740(ra) # 80000540 <panic>
    return -1;
    8000482c:	597d                	li	s2,-1
    8000482e:	b765                	j	800047d6 <fileread+0x60>
      return -1;
    80004830:	597d                	li	s2,-1
    80004832:	b755                	j	800047d6 <fileread+0x60>
    80004834:	597d                	li	s2,-1
    80004836:	b745                	j	800047d6 <fileread+0x60>

0000000080004838 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004838:	715d                	addi	sp,sp,-80
    8000483a:	e486                	sd	ra,72(sp)
    8000483c:	e0a2                	sd	s0,64(sp)
    8000483e:	fc26                	sd	s1,56(sp)
    80004840:	f84a                	sd	s2,48(sp)
    80004842:	f44e                	sd	s3,40(sp)
    80004844:	f052                	sd	s4,32(sp)
    80004846:	ec56                	sd	s5,24(sp)
    80004848:	e85a                	sd	s6,16(sp)
    8000484a:	e45e                	sd	s7,8(sp)
    8000484c:	e062                	sd	s8,0(sp)
    8000484e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004850:	00954783          	lbu	a5,9(a0)
    80004854:	10078663          	beqz	a5,80004960 <filewrite+0x128>
    80004858:	892a                	mv	s2,a0
    8000485a:	8b2e                	mv	s6,a1
    8000485c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000485e:	411c                	lw	a5,0(a0)
    80004860:	4705                	li	a4,1
    80004862:	02e78263          	beq	a5,a4,80004886 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004866:	470d                	li	a4,3
    80004868:	02e78663          	beq	a5,a4,80004894 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000486c:	4709                	li	a4,2
    8000486e:	0ee79163          	bne	a5,a4,80004950 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004872:	0ac05d63          	blez	a2,8000492c <filewrite+0xf4>
    int i = 0;
    80004876:	4981                	li	s3,0
    80004878:	6b85                	lui	s7,0x1
    8000487a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000487e:	6c05                	lui	s8,0x1
    80004880:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004884:	a861                	j	8000491c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004886:	6908                	ld	a0,16(a0)
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	22e080e7          	jalr	558(ra) # 80004ab6 <pipewrite>
    80004890:	8a2a                	mv	s4,a0
    80004892:	a045                	j	80004932 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004894:	02451783          	lh	a5,36(a0)
    80004898:	03079693          	slli	a3,a5,0x30
    8000489c:	92c1                	srli	a3,a3,0x30
    8000489e:	4725                	li	a4,9
    800048a0:	0cd76263          	bltu	a4,a3,80004964 <filewrite+0x12c>
    800048a4:	0792                	slli	a5,a5,0x4
    800048a6:	00034717          	auipc	a4,0x34
    800048aa:	54270713          	addi	a4,a4,1346 # 80038de8 <devsw>
    800048ae:	97ba                	add	a5,a5,a4
    800048b0:	679c                	ld	a5,8(a5)
    800048b2:	cbdd                	beqz	a5,80004968 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048b4:	4505                	li	a0,1
    800048b6:	9782                	jalr	a5
    800048b8:	8a2a                	mv	s4,a0
    800048ba:	a8a5                	j	80004932 <filewrite+0xfa>
    800048bc:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	8b4080e7          	jalr	-1868(ra) # 80004174 <begin_op>
      ilock(f->ip);
    800048c8:	01893503          	ld	a0,24(s2)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	edc080e7          	jalr	-292(ra) # 800037a8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048d4:	8756                	mv	a4,s5
    800048d6:	02092683          	lw	a3,32(s2)
    800048da:	01698633          	add	a2,s3,s6
    800048de:	4585                	li	a1,1
    800048e0:	01893503          	ld	a0,24(s2)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	270080e7          	jalr	624(ra) # 80003b54 <writei>
    800048ec:	84aa                	mv	s1,a0
    800048ee:	00a05763          	blez	a0,800048fc <filewrite+0xc4>
        f->off += r;
    800048f2:	02092783          	lw	a5,32(s2)
    800048f6:	9fa9                	addw	a5,a5,a0
    800048f8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048fc:	01893503          	ld	a0,24(s2)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	f6a080e7          	jalr	-150(ra) # 8000386a <iunlock>
      end_op();
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	8ea080e7          	jalr	-1814(ra) # 800041f2 <end_op>

      if(r != n1){
    80004910:	009a9f63          	bne	s5,s1,8000492e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004914:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004918:	0149db63          	bge	s3,s4,8000492e <filewrite+0xf6>
      int n1 = n - i;
    8000491c:	413a04bb          	subw	s1,s4,s3
    80004920:	0004879b          	sext.w	a5,s1
    80004924:	f8fbdce3          	bge	s7,a5,800048bc <filewrite+0x84>
    80004928:	84e2                	mv	s1,s8
    8000492a:	bf49                	j	800048bc <filewrite+0x84>
    int i = 0;
    8000492c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000492e:	013a1f63          	bne	s4,s3,8000494c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004932:	8552                	mv	a0,s4
    80004934:	60a6                	ld	ra,72(sp)
    80004936:	6406                	ld	s0,64(sp)
    80004938:	74e2                	ld	s1,56(sp)
    8000493a:	7942                	ld	s2,48(sp)
    8000493c:	79a2                	ld	s3,40(sp)
    8000493e:	7a02                	ld	s4,32(sp)
    80004940:	6ae2                	ld	s5,24(sp)
    80004942:	6b42                	ld	s6,16(sp)
    80004944:	6ba2                	ld	s7,8(sp)
    80004946:	6c02                	ld	s8,0(sp)
    80004948:	6161                	addi	sp,sp,80
    8000494a:	8082                	ret
    ret = (i == n ? n : -1);
    8000494c:	5a7d                	li	s4,-1
    8000494e:	b7d5                	j	80004932 <filewrite+0xfa>
    panic("filewrite");
    80004950:	00004517          	auipc	a0,0x4
    80004954:	d8850513          	addi	a0,a0,-632 # 800086d8 <syscalls+0x280>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	be8080e7          	jalr	-1048(ra) # 80000540 <panic>
    return -1;
    80004960:	5a7d                	li	s4,-1
    80004962:	bfc1                	j	80004932 <filewrite+0xfa>
      return -1;
    80004964:	5a7d                	li	s4,-1
    80004966:	b7f1                	j	80004932 <filewrite+0xfa>
    80004968:	5a7d                	li	s4,-1
    8000496a:	b7e1                	j	80004932 <filewrite+0xfa>

000000008000496c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000496c:	7179                	addi	sp,sp,-48
    8000496e:	f406                	sd	ra,40(sp)
    80004970:	f022                	sd	s0,32(sp)
    80004972:	ec26                	sd	s1,24(sp)
    80004974:	e84a                	sd	s2,16(sp)
    80004976:	e44e                	sd	s3,8(sp)
    80004978:	e052                	sd	s4,0(sp)
    8000497a:	1800                	addi	s0,sp,48
    8000497c:	84aa                	mv	s1,a0
    8000497e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004980:	0005b023          	sd	zero,0(a1)
    80004984:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	bf8080e7          	jalr	-1032(ra) # 80004580 <filealloc>
    80004990:	e088                	sd	a0,0(s1)
    80004992:	c551                	beqz	a0,80004a1e <pipealloc+0xb2>
    80004994:	00000097          	auipc	ra,0x0
    80004998:	bec080e7          	jalr	-1044(ra) # 80004580 <filealloc>
    8000499c:	00aa3023          	sd	a0,0(s4)
    800049a0:	c92d                	beqz	a0,80004a12 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	144080e7          	jalr	324(ra) # 80000ae6 <kalloc>
    800049aa:	892a                	mv	s2,a0
    800049ac:	c125                	beqz	a0,80004a0c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049ae:	4985                	li	s3,1
    800049b0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049b4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049b8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049bc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c0:	00004597          	auipc	a1,0x4
    800049c4:	d2858593          	addi	a1,a1,-728 # 800086e8 <syscalls+0x290>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	17e080e7          	jalr	382(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049d6:	609c                	ld	a5,0(s1)
    800049d8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049dc:	609c                	ld	a5,0(s1)
    800049de:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049e2:	609c                	ld	a5,0(s1)
    800049e4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049e8:	000a3783          	ld	a5,0(s4)
    800049ec:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049f8:	000a3783          	ld	a5,0(s4)
    800049fc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a00:	000a3783          	ld	a5,0(s4)
    80004a04:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a08:	4501                	li	a0,0
    80004a0a:	a025                	j	80004a32 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a0c:	6088                	ld	a0,0(s1)
    80004a0e:	e501                	bnez	a0,80004a16 <pipealloc+0xaa>
    80004a10:	a039                	j	80004a1e <pipealloc+0xb2>
    80004a12:	6088                	ld	a0,0(s1)
    80004a14:	c51d                	beqz	a0,80004a42 <pipealloc+0xd6>
    fileclose(*f0);
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	c26080e7          	jalr	-986(ra) # 8000463c <fileclose>
  if(*f1)
    80004a1e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a22:	557d                	li	a0,-1
  if(*f1)
    80004a24:	c799                	beqz	a5,80004a32 <pipealloc+0xc6>
    fileclose(*f1);
    80004a26:	853e                	mv	a0,a5
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	c14080e7          	jalr	-1004(ra) # 8000463c <fileclose>
  return -1;
    80004a30:	557d                	li	a0,-1
}
    80004a32:	70a2                	ld	ra,40(sp)
    80004a34:	7402                	ld	s0,32(sp)
    80004a36:	64e2                	ld	s1,24(sp)
    80004a38:	6942                	ld	s2,16(sp)
    80004a3a:	69a2                	ld	s3,8(sp)
    80004a3c:	6a02                	ld	s4,0(sp)
    80004a3e:	6145                	addi	sp,sp,48
    80004a40:	8082                	ret
  return -1;
    80004a42:	557d                	li	a0,-1
    80004a44:	b7fd                	j	80004a32 <pipealloc+0xc6>

0000000080004a46 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a46:	1101                	addi	sp,sp,-32
    80004a48:	ec06                	sd	ra,24(sp)
    80004a4a:	e822                	sd	s0,16(sp)
    80004a4c:	e426                	sd	s1,8(sp)
    80004a4e:	e04a                	sd	s2,0(sp)
    80004a50:	1000                	addi	s0,sp,32
    80004a52:	84aa                	mv	s1,a0
    80004a54:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	180080e7          	jalr	384(ra) # 80000bd6 <acquire>
  if(writable){
    80004a5e:	02090d63          	beqz	s2,80004a98 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a62:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a66:	21848513          	addi	a0,s1,536
    80004a6a:	ffffd097          	auipc	ra,0xffffd
    80004a6e:	64e080e7          	jalr	1614(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a72:	2204b783          	ld	a5,544(s1)
    80004a76:	eb95                	bnez	a5,80004aaa <pipeclose+0x64>
    release(&pi->lock);
    80004a78:	8526                	mv	a0,s1
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	210080e7          	jalr	528(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	f64080e7          	jalr	-156(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6902                	ld	s2,0(sp)
    80004a94:	6105                	addi	sp,sp,32
    80004a96:	8082                	ret
    pi->readopen = 0;
    80004a98:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a9c:	21c48513          	addi	a0,s1,540
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	618080e7          	jalr	1560(ra) # 800020b8 <wakeup>
    80004aa8:	b7e9                	j	80004a72 <pipeclose+0x2c>
    release(&pi->lock);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	1de080e7          	jalr	478(ra) # 80000c8a <release>
}
    80004ab4:	bfe1                	j	80004a8c <pipeclose+0x46>

0000000080004ab6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ab6:	711d                	addi	sp,sp,-96
    80004ab8:	ec86                	sd	ra,88(sp)
    80004aba:	e8a2                	sd	s0,80(sp)
    80004abc:	e4a6                	sd	s1,72(sp)
    80004abe:	e0ca                	sd	s2,64(sp)
    80004ac0:	fc4e                	sd	s3,56(sp)
    80004ac2:	f852                	sd	s4,48(sp)
    80004ac4:	f456                	sd	s5,40(sp)
    80004ac6:	f05a                	sd	s6,32(sp)
    80004ac8:	ec5e                	sd	s7,24(sp)
    80004aca:	e862                	sd	s8,16(sp)
    80004acc:	1080                	addi	s0,sp,96
    80004ace:	84aa                	mv	s1,a0
    80004ad0:	8aae                	mv	s5,a1
    80004ad2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	ed8080e7          	jalr	-296(ra) # 800019ac <myproc>
    80004adc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	0f6080e7          	jalr	246(ra) # 80000bd6 <acquire>
  while(i < n){
    80004ae8:	0b405663          	blez	s4,80004b94 <pipewrite+0xde>
  int i = 0;
    80004aec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004af0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af4:	21c48b93          	addi	s7,s1,540
    80004af8:	a089                	j	80004b3a <pipewrite+0x84>
      release(&pi->lock);
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	18e080e7          	jalr	398(ra) # 80000c8a <release>
      return -1;
    80004b04:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b06:	854a                	mv	a0,s2
    80004b08:	60e6                	ld	ra,88(sp)
    80004b0a:	6446                	ld	s0,80(sp)
    80004b0c:	64a6                	ld	s1,72(sp)
    80004b0e:	6906                	ld	s2,64(sp)
    80004b10:	79e2                	ld	s3,56(sp)
    80004b12:	7a42                	ld	s4,48(sp)
    80004b14:	7aa2                	ld	s5,40(sp)
    80004b16:	7b02                	ld	s6,32(sp)
    80004b18:	6be2                	ld	s7,24(sp)
    80004b1a:	6c42                	ld	s8,16(sp)
    80004b1c:	6125                	addi	sp,sp,96
    80004b1e:	8082                	ret
      wakeup(&pi->nread);
    80004b20:	8562                	mv	a0,s8
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	596080e7          	jalr	1430(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b2a:	85a6                	mv	a1,s1
    80004b2c:	855e                	mv	a0,s7
    80004b2e:	ffffd097          	auipc	ra,0xffffd
    80004b32:	526080e7          	jalr	1318(ra) # 80002054 <sleep>
  while(i < n){
    80004b36:	07495063          	bge	s2,s4,80004b96 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b3a:	2204a783          	lw	a5,544(s1)
    80004b3e:	dfd5                	beqz	a5,80004afa <pipewrite+0x44>
    80004b40:	854e                	mv	a0,s3
    80004b42:	ffffd097          	auipc	ra,0xffffd
    80004b46:	7ba080e7          	jalr	1978(ra) # 800022fc <killed>
    80004b4a:	f945                	bnez	a0,80004afa <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b4c:	2184a783          	lw	a5,536(s1)
    80004b50:	21c4a703          	lw	a4,540(s1)
    80004b54:	2007879b          	addiw	a5,a5,512
    80004b58:	fcf704e3          	beq	a4,a5,80004b20 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b5c:	4685                	li	a3,1
    80004b5e:	01590633          	add	a2,s2,s5
    80004b62:	faf40593          	addi	a1,s0,-81
    80004b66:	0509b503          	ld	a0,80(s3)
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	b8e080e7          	jalr	-1138(ra) # 800016f8 <copyin>
    80004b72:	03650263          	beq	a0,s6,80004b96 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b76:	21c4a783          	lw	a5,540(s1)
    80004b7a:	0017871b          	addiw	a4,a5,1
    80004b7e:	20e4ae23          	sw	a4,540(s1)
    80004b82:	1ff7f793          	andi	a5,a5,511
    80004b86:	97a6                	add	a5,a5,s1
    80004b88:	faf44703          	lbu	a4,-81(s0)
    80004b8c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b90:	2905                	addiw	s2,s2,1
    80004b92:	b755                	j	80004b36 <pipewrite+0x80>
  int i = 0;
    80004b94:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b96:	21848513          	addi	a0,s1,536
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	51e080e7          	jalr	1310(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	0e6080e7          	jalr	230(ra) # 80000c8a <release>
  return i;
    80004bac:	bfa9                	j	80004b06 <pipewrite+0x50>

0000000080004bae <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bae:	715d                	addi	sp,sp,-80
    80004bb0:	e486                	sd	ra,72(sp)
    80004bb2:	e0a2                	sd	s0,64(sp)
    80004bb4:	fc26                	sd	s1,56(sp)
    80004bb6:	f84a                	sd	s2,48(sp)
    80004bb8:	f44e                	sd	s3,40(sp)
    80004bba:	f052                	sd	s4,32(sp)
    80004bbc:	ec56                	sd	s5,24(sp)
    80004bbe:	e85a                	sd	s6,16(sp)
    80004bc0:	0880                	addi	s0,sp,80
    80004bc2:	84aa                	mv	s1,a0
    80004bc4:	892e                	mv	s2,a1
    80004bc6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	de4080e7          	jalr	-540(ra) # 800019ac <myproc>
    80004bd0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bdc:	2184a703          	lw	a4,536(s1)
    80004be0:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004be4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be8:	02f71763          	bne	a4,a5,80004c16 <piperead+0x68>
    80004bec:	2244a783          	lw	a5,548(s1)
    80004bf0:	c39d                	beqz	a5,80004c16 <piperead+0x68>
    if(killed(pr)){
    80004bf2:	8552                	mv	a0,s4
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	708080e7          	jalr	1800(ra) # 800022fc <killed>
    80004bfc:	e949                	bnez	a0,80004c8e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bfe:	85a6                	mv	a1,s1
    80004c00:	854e                	mv	a0,s3
    80004c02:	ffffd097          	auipc	ra,0xffffd
    80004c06:	452080e7          	jalr	1106(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c0a:	2184a703          	lw	a4,536(s1)
    80004c0e:	21c4a783          	lw	a5,540(s1)
    80004c12:	fcf70de3          	beq	a4,a5,80004bec <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c16:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c18:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c1a:	05505463          	blez	s5,80004c62 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c1e:	2184a783          	lw	a5,536(s1)
    80004c22:	21c4a703          	lw	a4,540(s1)
    80004c26:	02f70e63          	beq	a4,a5,80004c62 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c2a:	0017871b          	addiw	a4,a5,1
    80004c2e:	20e4ac23          	sw	a4,536(s1)
    80004c32:	1ff7f793          	andi	a5,a5,511
    80004c36:	97a6                	add	a5,a5,s1
    80004c38:	0187c783          	lbu	a5,24(a5)
    80004c3c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c40:	4685                	li	a3,1
    80004c42:	fbf40613          	addi	a2,s0,-65
    80004c46:	85ca                	mv	a1,s2
    80004c48:	050a3503          	ld	a0,80(s4)
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	a20080e7          	jalr	-1504(ra) # 8000166c <copyout>
    80004c54:	01650763          	beq	a0,s6,80004c62 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c58:	2985                	addiw	s3,s3,1
    80004c5a:	0905                	addi	s2,s2,1
    80004c5c:	fd3a91e3          	bne	s5,s3,80004c1e <piperead+0x70>
    80004c60:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c62:	21c48513          	addi	a0,s1,540
    80004c66:	ffffd097          	auipc	ra,0xffffd
    80004c6a:	452080e7          	jalr	1106(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004c6e:	8526                	mv	a0,s1
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	01a080e7          	jalr	26(ra) # 80000c8a <release>
  return i;
}
    80004c78:	854e                	mv	a0,s3
    80004c7a:	60a6                	ld	ra,72(sp)
    80004c7c:	6406                	ld	s0,64(sp)
    80004c7e:	74e2                	ld	s1,56(sp)
    80004c80:	7942                	ld	s2,48(sp)
    80004c82:	79a2                	ld	s3,40(sp)
    80004c84:	7a02                	ld	s4,32(sp)
    80004c86:	6ae2                	ld	s5,24(sp)
    80004c88:	6b42                	ld	s6,16(sp)
    80004c8a:	6161                	addi	sp,sp,80
    80004c8c:	8082                	ret
      release(&pi->lock);
    80004c8e:	8526                	mv	a0,s1
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	ffa080e7          	jalr	-6(ra) # 80000c8a <release>
      return -1;
    80004c98:	59fd                	li	s3,-1
    80004c9a:	bff9                	j	80004c78 <piperead+0xca>

0000000080004c9c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c9c:	1141                	addi	sp,sp,-16
    80004c9e:	e422                	sd	s0,8(sp)
    80004ca0:	0800                	addi	s0,sp,16
    80004ca2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ca4:	8905                	andi	a0,a0,1
    80004ca6:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004ca8:	8b89                	andi	a5,a5,2
    80004caa:	c399                	beqz	a5,80004cb0 <flags2perm+0x14>
      perm |= PTE_W;
    80004cac:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cb0:	6422                	ld	s0,8(sp)
    80004cb2:	0141                	addi	sp,sp,16
    80004cb4:	8082                	ret

0000000080004cb6 <exec>:

int
exec(char *path, char **argv)
{
    80004cb6:	de010113          	addi	sp,sp,-544
    80004cba:	20113c23          	sd	ra,536(sp)
    80004cbe:	20813823          	sd	s0,528(sp)
    80004cc2:	20913423          	sd	s1,520(sp)
    80004cc6:	21213023          	sd	s2,512(sp)
    80004cca:	ffce                	sd	s3,504(sp)
    80004ccc:	fbd2                	sd	s4,496(sp)
    80004cce:	f7d6                	sd	s5,488(sp)
    80004cd0:	f3da                	sd	s6,480(sp)
    80004cd2:	efde                	sd	s7,472(sp)
    80004cd4:	ebe2                	sd	s8,464(sp)
    80004cd6:	e7e6                	sd	s9,456(sp)
    80004cd8:	e3ea                	sd	s10,448(sp)
    80004cda:	ff6e                	sd	s11,440(sp)
    80004cdc:	1400                	addi	s0,sp,544
    80004cde:	892a                	mv	s2,a0
    80004ce0:	dea43423          	sd	a0,-536(s0)
    80004ce4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	cc4080e7          	jalr	-828(ra) # 800019ac <myproc>
    80004cf0:	84aa                	mv	s1,a0

  begin_op();
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	482080e7          	jalr	1154(ra) # 80004174 <begin_op>

  if((ip = namei(path)) == 0){
    80004cfa:	854a                	mv	a0,s2
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	258080e7          	jalr	600(ra) # 80003f54 <namei>
    80004d04:	c93d                	beqz	a0,80004d7a <exec+0xc4>
    80004d06:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	aa0080e7          	jalr	-1376(ra) # 800037a8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d10:	04000713          	li	a4,64
    80004d14:	4681                	li	a3,0
    80004d16:	e5040613          	addi	a2,s0,-432
    80004d1a:	4581                	li	a1,0
    80004d1c:	8556                	mv	a0,s5
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	d3e080e7          	jalr	-706(ra) # 80003a5c <readi>
    80004d26:	04000793          	li	a5,64
    80004d2a:	00f51a63          	bne	a0,a5,80004d3e <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d2e:	e5042703          	lw	a4,-432(s0)
    80004d32:	464c47b7          	lui	a5,0x464c4
    80004d36:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d3a:	04f70663          	beq	a4,a5,80004d86 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d3e:	8556                	mv	a0,s5
    80004d40:	fffff097          	auipc	ra,0xfffff
    80004d44:	cca080e7          	jalr	-822(ra) # 80003a0a <iunlockput>
    end_op();
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	4aa080e7          	jalr	1194(ra) # 800041f2 <end_op>
  }
  return -1;
    80004d50:	557d                	li	a0,-1
}
    80004d52:	21813083          	ld	ra,536(sp)
    80004d56:	21013403          	ld	s0,528(sp)
    80004d5a:	20813483          	ld	s1,520(sp)
    80004d5e:	20013903          	ld	s2,512(sp)
    80004d62:	79fe                	ld	s3,504(sp)
    80004d64:	7a5e                	ld	s4,496(sp)
    80004d66:	7abe                	ld	s5,488(sp)
    80004d68:	7b1e                	ld	s6,480(sp)
    80004d6a:	6bfe                	ld	s7,472(sp)
    80004d6c:	6c5e                	ld	s8,464(sp)
    80004d6e:	6cbe                	ld	s9,456(sp)
    80004d70:	6d1e                	ld	s10,448(sp)
    80004d72:	7dfa                	ld	s11,440(sp)
    80004d74:	22010113          	addi	sp,sp,544
    80004d78:	8082                	ret
    end_op();
    80004d7a:	fffff097          	auipc	ra,0xfffff
    80004d7e:	478080e7          	jalr	1144(ra) # 800041f2 <end_op>
    return -1;
    80004d82:	557d                	li	a0,-1
    80004d84:	b7f9                	j	80004d52 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d86:	8526                	mv	a0,s1
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	ce8080e7          	jalr	-792(ra) # 80001a70 <proc_pagetable>
    80004d90:	8b2a                	mv	s6,a0
    80004d92:	d555                	beqz	a0,80004d3e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d94:	e7042783          	lw	a5,-400(s0)
    80004d98:	e8845703          	lhu	a4,-376(s0)
    80004d9c:	c735                	beqz	a4,80004e08 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d9e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004da4:	6a05                	lui	s4,0x1
    80004da6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004daa:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004dae:	6d85                	lui	s11,0x1
    80004db0:	7d7d                	lui	s10,0xfffff
    80004db2:	ac3d                	j	80004ff0 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004db4:	00004517          	auipc	a0,0x4
    80004db8:	93c50513          	addi	a0,a0,-1732 # 800086f0 <syscalls+0x298>
    80004dbc:	ffffb097          	auipc	ra,0xffffb
    80004dc0:	784080e7          	jalr	1924(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dc4:	874a                	mv	a4,s2
    80004dc6:	009c86bb          	addw	a3,s9,s1
    80004dca:	4581                	li	a1,0
    80004dcc:	8556                	mv	a0,s5
    80004dce:	fffff097          	auipc	ra,0xfffff
    80004dd2:	c8e080e7          	jalr	-882(ra) # 80003a5c <readi>
    80004dd6:	2501                	sext.w	a0,a0
    80004dd8:	1aa91963          	bne	s2,a0,80004f8a <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004ddc:	009d84bb          	addw	s1,s11,s1
    80004de0:	013d09bb          	addw	s3,s10,s3
    80004de4:	1f74f663          	bgeu	s1,s7,80004fd0 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004de8:	02049593          	slli	a1,s1,0x20
    80004dec:	9181                	srli	a1,a1,0x20
    80004dee:	95e2                	add	a1,a1,s8
    80004df0:	855a                	mv	a0,s6
    80004df2:	ffffc097          	auipc	ra,0xffffc
    80004df6:	26a080e7          	jalr	618(ra) # 8000105c <walkaddr>
    80004dfa:	862a                	mv	a2,a0
    if(pa == 0)
    80004dfc:	dd45                	beqz	a0,80004db4 <exec+0xfe>
      n = PGSIZE;
    80004dfe:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e00:	fd49f2e3          	bgeu	s3,s4,80004dc4 <exec+0x10e>
      n = sz - i;
    80004e04:	894e                	mv	s2,s3
    80004e06:	bf7d                	j	80004dc4 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e08:	4901                	li	s2,0
  iunlockput(ip);
    80004e0a:	8556                	mv	a0,s5
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	bfe080e7          	jalr	-1026(ra) # 80003a0a <iunlockput>
  end_op();
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	3de080e7          	jalr	990(ra) # 800041f2 <end_op>
  p = myproc();
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	b90080e7          	jalr	-1136(ra) # 800019ac <myproc>
    80004e24:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e26:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e2a:	6785                	lui	a5,0x1
    80004e2c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e2e:	97ca                	add	a5,a5,s2
    80004e30:	777d                	lui	a4,0xfffff
    80004e32:	8ff9                	and	a5,a5,a4
    80004e34:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e38:	4691                	li	a3,4
    80004e3a:	6609                	lui	a2,0x2
    80004e3c:	963e                	add	a2,a2,a5
    80004e3e:	85be                	mv	a1,a5
    80004e40:	855a                	mv	a0,s6
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	5ce080e7          	jalr	1486(ra) # 80001410 <uvmalloc>
    80004e4a:	8c2a                	mv	s8,a0
  ip = 0;
    80004e4c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e4e:	12050e63          	beqz	a0,80004f8a <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e52:	75f9                	lui	a1,0xffffe
    80004e54:	95aa                	add	a1,a1,a0
    80004e56:	855a                	mv	a0,s6
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	7e2080e7          	jalr	2018(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e60:	7afd                	lui	s5,0xfffff
    80004e62:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e64:	df043783          	ld	a5,-528(s0)
    80004e68:	6388                	ld	a0,0(a5)
    80004e6a:	c925                	beqz	a0,80004eda <exec+0x224>
    80004e6c:	e9040993          	addi	s3,s0,-368
    80004e70:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e74:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e76:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	fd6080e7          	jalr	-42(ra) # 80000e4e <strlen>
    80004e80:	0015079b          	addiw	a5,a0,1
    80004e84:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e88:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e8c:	13596663          	bltu	s2,s5,80004fb8 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e90:	df043d83          	ld	s11,-528(s0)
    80004e94:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e98:	8552                	mv	a0,s4
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	fb4080e7          	jalr	-76(ra) # 80000e4e <strlen>
    80004ea2:	0015069b          	addiw	a3,a0,1
    80004ea6:	8652                	mv	a2,s4
    80004ea8:	85ca                	mv	a1,s2
    80004eaa:	855a                	mv	a0,s6
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	7c0080e7          	jalr	1984(ra) # 8000166c <copyout>
    80004eb4:	10054663          	bltz	a0,80004fc0 <exec+0x30a>
    ustack[argc] = sp;
    80004eb8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ebc:	0485                	addi	s1,s1,1
    80004ebe:	008d8793          	addi	a5,s11,8
    80004ec2:	def43823          	sd	a5,-528(s0)
    80004ec6:	008db503          	ld	a0,8(s11)
    80004eca:	c911                	beqz	a0,80004ede <exec+0x228>
    if(argc >= MAXARG)
    80004ecc:	09a1                	addi	s3,s3,8
    80004ece:	fb3c95e3          	bne	s9,s3,80004e78 <exec+0x1c2>
  sz = sz1;
    80004ed2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ed6:	4a81                	li	s5,0
    80004ed8:	a84d                	j	80004f8a <exec+0x2d4>
  sp = sz;
    80004eda:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004edc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ede:	00349793          	slli	a5,s1,0x3
    80004ee2:	f9078793          	addi	a5,a5,-112
    80004ee6:	97a2                	add	a5,a5,s0
    80004ee8:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004eec:	00148693          	addi	a3,s1,1
    80004ef0:	068e                	slli	a3,a3,0x3
    80004ef2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ef6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004efa:	01597663          	bgeu	s2,s5,80004f06 <exec+0x250>
  sz = sz1;
    80004efe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f02:	4a81                	li	s5,0
    80004f04:	a059                	j	80004f8a <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f06:	e9040613          	addi	a2,s0,-368
    80004f0a:	85ca                	mv	a1,s2
    80004f0c:	855a                	mv	a0,s6
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	75e080e7          	jalr	1886(ra) # 8000166c <copyout>
    80004f16:	0a054963          	bltz	a0,80004fc8 <exec+0x312>
  p->trapframe->a1 = sp;
    80004f1a:	058bb783          	ld	a5,88(s7)
    80004f1e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f22:	de843783          	ld	a5,-536(s0)
    80004f26:	0007c703          	lbu	a4,0(a5)
    80004f2a:	cf11                	beqz	a4,80004f46 <exec+0x290>
    80004f2c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f2e:	02f00693          	li	a3,47
    80004f32:	a039                	j	80004f40 <exec+0x28a>
      last = s+1;
    80004f34:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f38:	0785                	addi	a5,a5,1
    80004f3a:	fff7c703          	lbu	a4,-1(a5)
    80004f3e:	c701                	beqz	a4,80004f46 <exec+0x290>
    if(*s == '/')
    80004f40:	fed71ce3          	bne	a4,a3,80004f38 <exec+0x282>
    80004f44:	bfc5                	j	80004f34 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f46:	4641                	li	a2,16
    80004f48:	de843583          	ld	a1,-536(s0)
    80004f4c:	158b8513          	addi	a0,s7,344
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	ecc080e7          	jalr	-308(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f58:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f5c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f60:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f64:	058bb783          	ld	a5,88(s7)
    80004f68:	e6843703          	ld	a4,-408(s0)
    80004f6c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f6e:	058bb783          	ld	a5,88(s7)
    80004f72:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f76:	85ea                	mv	a1,s10
    80004f78:	ffffd097          	auipc	ra,0xffffd
    80004f7c:	b94080e7          	jalr	-1132(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f80:	0004851b          	sext.w	a0,s1
    80004f84:	b3f9                	j	80004d52 <exec+0x9c>
    80004f86:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f8a:	df843583          	ld	a1,-520(s0)
    80004f8e:	855a                	mv	a0,s6
    80004f90:	ffffd097          	auipc	ra,0xffffd
    80004f94:	b7c080e7          	jalr	-1156(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004f98:	da0a93e3          	bnez	s5,80004d3e <exec+0x88>
  return -1;
    80004f9c:	557d                	li	a0,-1
    80004f9e:	bb55                	j	80004d52 <exec+0x9c>
    80004fa0:	df243c23          	sd	s2,-520(s0)
    80004fa4:	b7dd                	j	80004f8a <exec+0x2d4>
    80004fa6:	df243c23          	sd	s2,-520(s0)
    80004faa:	b7c5                	j	80004f8a <exec+0x2d4>
    80004fac:	df243c23          	sd	s2,-520(s0)
    80004fb0:	bfe9                	j	80004f8a <exec+0x2d4>
    80004fb2:	df243c23          	sd	s2,-520(s0)
    80004fb6:	bfd1                	j	80004f8a <exec+0x2d4>
  sz = sz1;
    80004fb8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fbc:	4a81                	li	s5,0
    80004fbe:	b7f1                	j	80004f8a <exec+0x2d4>
  sz = sz1;
    80004fc0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fc4:	4a81                	li	s5,0
    80004fc6:	b7d1                	j	80004f8a <exec+0x2d4>
  sz = sz1;
    80004fc8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fcc:	4a81                	li	s5,0
    80004fce:	bf75                	j	80004f8a <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fd0:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd4:	e0843783          	ld	a5,-504(s0)
    80004fd8:	0017869b          	addiw	a3,a5,1
    80004fdc:	e0d43423          	sd	a3,-504(s0)
    80004fe0:	e0043783          	ld	a5,-512(s0)
    80004fe4:	0387879b          	addiw	a5,a5,56
    80004fe8:	e8845703          	lhu	a4,-376(s0)
    80004fec:	e0e6dfe3          	bge	a3,a4,80004e0a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ff0:	2781                	sext.w	a5,a5
    80004ff2:	e0f43023          	sd	a5,-512(s0)
    80004ff6:	03800713          	li	a4,56
    80004ffa:	86be                	mv	a3,a5
    80004ffc:	e1840613          	addi	a2,s0,-488
    80005000:	4581                	li	a1,0
    80005002:	8556                	mv	a0,s5
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	a58080e7          	jalr	-1448(ra) # 80003a5c <readi>
    8000500c:	03800793          	li	a5,56
    80005010:	f6f51be3          	bne	a0,a5,80004f86 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005014:	e1842783          	lw	a5,-488(s0)
    80005018:	4705                	li	a4,1
    8000501a:	fae79de3          	bne	a5,a4,80004fd4 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000501e:	e4043483          	ld	s1,-448(s0)
    80005022:	e3843783          	ld	a5,-456(s0)
    80005026:	f6f4ede3          	bltu	s1,a5,80004fa0 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000502a:	e2843783          	ld	a5,-472(s0)
    8000502e:	94be                	add	s1,s1,a5
    80005030:	f6f4ebe3          	bltu	s1,a5,80004fa6 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005034:	de043703          	ld	a4,-544(s0)
    80005038:	8ff9                	and	a5,a5,a4
    8000503a:	fbad                	bnez	a5,80004fac <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000503c:	e1c42503          	lw	a0,-484(s0)
    80005040:	00000097          	auipc	ra,0x0
    80005044:	c5c080e7          	jalr	-932(ra) # 80004c9c <flags2perm>
    80005048:	86aa                	mv	a3,a0
    8000504a:	8626                	mv	a2,s1
    8000504c:	85ca                	mv	a1,s2
    8000504e:	855a                	mv	a0,s6
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	3c0080e7          	jalr	960(ra) # 80001410 <uvmalloc>
    80005058:	dea43c23          	sd	a0,-520(s0)
    8000505c:	d939                	beqz	a0,80004fb2 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000505e:	e2843c03          	ld	s8,-472(s0)
    80005062:	e2042c83          	lw	s9,-480(s0)
    80005066:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000506a:	f60b83e3          	beqz	s7,80004fd0 <exec+0x31a>
    8000506e:	89de                	mv	s3,s7
    80005070:	4481                	li	s1,0
    80005072:	bb9d                	j	80004de8 <exec+0x132>

0000000080005074 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005074:	7179                	addi	sp,sp,-48
    80005076:	f406                	sd	ra,40(sp)
    80005078:	f022                	sd	s0,32(sp)
    8000507a:	ec26                	sd	s1,24(sp)
    8000507c:	e84a                	sd	s2,16(sp)
    8000507e:	1800                	addi	s0,sp,48
    80005080:	892e                	mv	s2,a1
    80005082:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005084:	fdc40593          	addi	a1,s0,-36
    80005088:	ffffe097          	auipc	ra,0xffffe
    8000508c:	ae4080e7          	jalr	-1308(ra) # 80002b6c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005090:	fdc42703          	lw	a4,-36(s0)
    80005094:	47bd                	li	a5,15
    80005096:	02e7eb63          	bltu	a5,a4,800050cc <argfd+0x58>
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	912080e7          	jalr	-1774(ra) # 800019ac <myproc>
    800050a2:	fdc42703          	lw	a4,-36(s0)
    800050a6:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffc509a>
    800050aa:	078e                	slli	a5,a5,0x3
    800050ac:	953e                	add	a0,a0,a5
    800050ae:	611c                	ld	a5,0(a0)
    800050b0:	c385                	beqz	a5,800050d0 <argfd+0x5c>
    return -1;
  if(pfd)
    800050b2:	00090463          	beqz	s2,800050ba <argfd+0x46>
    *pfd = fd;
    800050b6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050ba:	4501                	li	a0,0
  if(pf)
    800050bc:	c091                	beqz	s1,800050c0 <argfd+0x4c>
    *pf = f;
    800050be:	e09c                	sd	a5,0(s1)
}
    800050c0:	70a2                	ld	ra,40(sp)
    800050c2:	7402                	ld	s0,32(sp)
    800050c4:	64e2                	ld	s1,24(sp)
    800050c6:	6942                	ld	s2,16(sp)
    800050c8:	6145                	addi	sp,sp,48
    800050ca:	8082                	ret
    return -1;
    800050cc:	557d                	li	a0,-1
    800050ce:	bfcd                	j	800050c0 <argfd+0x4c>
    800050d0:	557d                	li	a0,-1
    800050d2:	b7fd                	j	800050c0 <argfd+0x4c>

00000000800050d4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050d4:	1101                	addi	sp,sp,-32
    800050d6:	ec06                	sd	ra,24(sp)
    800050d8:	e822                	sd	s0,16(sp)
    800050da:	e426                	sd	s1,8(sp)
    800050dc:	1000                	addi	s0,sp,32
    800050de:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050e0:	ffffd097          	auipc	ra,0xffffd
    800050e4:	8cc080e7          	jalr	-1844(ra) # 800019ac <myproc>
    800050e8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050ea:	0d050793          	addi	a5,a0,208
    800050ee:	4501                	li	a0,0
    800050f0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050f2:	6398                	ld	a4,0(a5)
    800050f4:	cb19                	beqz	a4,8000510a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050f6:	2505                	addiw	a0,a0,1
    800050f8:	07a1                	addi	a5,a5,8
    800050fa:	fed51ce3          	bne	a0,a3,800050f2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050fe:	557d                	li	a0,-1
}
    80005100:	60e2                	ld	ra,24(sp)
    80005102:	6442                	ld	s0,16(sp)
    80005104:	64a2                	ld	s1,8(sp)
    80005106:	6105                	addi	sp,sp,32
    80005108:	8082                	ret
      p->ofile[fd] = f;
    8000510a:	01a50793          	addi	a5,a0,26
    8000510e:	078e                	slli	a5,a5,0x3
    80005110:	963e                	add	a2,a2,a5
    80005112:	e204                	sd	s1,0(a2)
      return fd;
    80005114:	b7f5                	j	80005100 <fdalloc+0x2c>

0000000080005116 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005116:	715d                	addi	sp,sp,-80
    80005118:	e486                	sd	ra,72(sp)
    8000511a:	e0a2                	sd	s0,64(sp)
    8000511c:	fc26                	sd	s1,56(sp)
    8000511e:	f84a                	sd	s2,48(sp)
    80005120:	f44e                	sd	s3,40(sp)
    80005122:	f052                	sd	s4,32(sp)
    80005124:	ec56                	sd	s5,24(sp)
    80005126:	e85a                	sd	s6,16(sp)
    80005128:	0880                	addi	s0,sp,80
    8000512a:	8b2e                	mv	s6,a1
    8000512c:	89b2                	mv	s3,a2
    8000512e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005130:	fb040593          	addi	a1,s0,-80
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	e3e080e7          	jalr	-450(ra) # 80003f72 <nameiparent>
    8000513c:	84aa                	mv	s1,a0
    8000513e:	14050f63          	beqz	a0,8000529c <create+0x186>
    return 0;

  ilock(dp);
    80005142:	ffffe097          	auipc	ra,0xffffe
    80005146:	666080e7          	jalr	1638(ra) # 800037a8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000514a:	4601                	li	a2,0
    8000514c:	fb040593          	addi	a1,s0,-80
    80005150:	8526                	mv	a0,s1
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	b3a080e7          	jalr	-1222(ra) # 80003c8c <dirlookup>
    8000515a:	8aaa                	mv	s5,a0
    8000515c:	c931                	beqz	a0,800051b0 <create+0x9a>
    iunlockput(dp);
    8000515e:	8526                	mv	a0,s1
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	8aa080e7          	jalr	-1878(ra) # 80003a0a <iunlockput>
    ilock(ip);
    80005168:	8556                	mv	a0,s5
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	63e080e7          	jalr	1598(ra) # 800037a8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005172:	000b059b          	sext.w	a1,s6
    80005176:	4789                	li	a5,2
    80005178:	02f59563          	bne	a1,a5,800051a2 <create+0x8c>
    8000517c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffc50c4>
    80005180:	37f9                	addiw	a5,a5,-2
    80005182:	17c2                	slli	a5,a5,0x30
    80005184:	93c1                	srli	a5,a5,0x30
    80005186:	4705                	li	a4,1
    80005188:	00f76d63          	bltu	a4,a5,800051a2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000518c:	8556                	mv	a0,s5
    8000518e:	60a6                	ld	ra,72(sp)
    80005190:	6406                	ld	s0,64(sp)
    80005192:	74e2                	ld	s1,56(sp)
    80005194:	7942                	ld	s2,48(sp)
    80005196:	79a2                	ld	s3,40(sp)
    80005198:	7a02                	ld	s4,32(sp)
    8000519a:	6ae2                	ld	s5,24(sp)
    8000519c:	6b42                	ld	s6,16(sp)
    8000519e:	6161                	addi	sp,sp,80
    800051a0:	8082                	ret
    iunlockput(ip);
    800051a2:	8556                	mv	a0,s5
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	866080e7          	jalr	-1946(ra) # 80003a0a <iunlockput>
    return 0;
    800051ac:	4a81                	li	s5,0
    800051ae:	bff9                	j	8000518c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051b0:	85da                	mv	a1,s6
    800051b2:	4088                	lw	a0,0(s1)
    800051b4:	ffffe097          	auipc	ra,0xffffe
    800051b8:	456080e7          	jalr	1110(ra) # 8000360a <ialloc>
    800051bc:	8a2a                	mv	s4,a0
    800051be:	c539                	beqz	a0,8000520c <create+0xf6>
  ilock(ip);
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	5e8080e7          	jalr	1512(ra) # 800037a8 <ilock>
  ip->major = major;
    800051c8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051cc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051d0:	4905                	li	s2,1
    800051d2:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051d6:	8552                	mv	a0,s4
    800051d8:	ffffe097          	auipc	ra,0xffffe
    800051dc:	504080e7          	jalr	1284(ra) # 800036dc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051e0:	000b059b          	sext.w	a1,s6
    800051e4:	03258b63          	beq	a1,s2,8000521a <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051e8:	004a2603          	lw	a2,4(s4)
    800051ec:	fb040593          	addi	a1,s0,-80
    800051f0:	8526                	mv	a0,s1
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	cb0080e7          	jalr	-848(ra) # 80003ea2 <dirlink>
    800051fa:	06054f63          	bltz	a0,80005278 <create+0x162>
  iunlockput(dp);
    800051fe:	8526                	mv	a0,s1
    80005200:	fffff097          	auipc	ra,0xfffff
    80005204:	80a080e7          	jalr	-2038(ra) # 80003a0a <iunlockput>
  return ip;
    80005208:	8ad2                	mv	s5,s4
    8000520a:	b749                	j	8000518c <create+0x76>
    iunlockput(dp);
    8000520c:	8526                	mv	a0,s1
    8000520e:	ffffe097          	auipc	ra,0xffffe
    80005212:	7fc080e7          	jalr	2044(ra) # 80003a0a <iunlockput>
    return 0;
    80005216:	8ad2                	mv	s5,s4
    80005218:	bf95                	j	8000518c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000521a:	004a2603          	lw	a2,4(s4)
    8000521e:	00003597          	auipc	a1,0x3
    80005222:	4f258593          	addi	a1,a1,1266 # 80008710 <syscalls+0x2b8>
    80005226:	8552                	mv	a0,s4
    80005228:	fffff097          	auipc	ra,0xfffff
    8000522c:	c7a080e7          	jalr	-902(ra) # 80003ea2 <dirlink>
    80005230:	04054463          	bltz	a0,80005278 <create+0x162>
    80005234:	40d0                	lw	a2,4(s1)
    80005236:	00003597          	auipc	a1,0x3
    8000523a:	4e258593          	addi	a1,a1,1250 # 80008718 <syscalls+0x2c0>
    8000523e:	8552                	mv	a0,s4
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	c62080e7          	jalr	-926(ra) # 80003ea2 <dirlink>
    80005248:	02054863          	bltz	a0,80005278 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000524c:	004a2603          	lw	a2,4(s4)
    80005250:	fb040593          	addi	a1,s0,-80
    80005254:	8526                	mv	a0,s1
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	c4c080e7          	jalr	-948(ra) # 80003ea2 <dirlink>
    8000525e:	00054d63          	bltz	a0,80005278 <create+0x162>
    dp->nlink++;  // for ".."
    80005262:	04a4d783          	lhu	a5,74(s1)
    80005266:	2785                	addiw	a5,a5,1
    80005268:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000526c:	8526                	mv	a0,s1
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	46e080e7          	jalr	1134(ra) # 800036dc <iupdate>
    80005276:	b761                	j	800051fe <create+0xe8>
  ip->nlink = 0;
    80005278:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000527c:	8552                	mv	a0,s4
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	45e080e7          	jalr	1118(ra) # 800036dc <iupdate>
  iunlockput(ip);
    80005286:	8552                	mv	a0,s4
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	782080e7          	jalr	1922(ra) # 80003a0a <iunlockput>
  iunlockput(dp);
    80005290:	8526                	mv	a0,s1
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	778080e7          	jalr	1912(ra) # 80003a0a <iunlockput>
  return 0;
    8000529a:	bdcd                	j	8000518c <create+0x76>
    return 0;
    8000529c:	8aaa                	mv	s5,a0
    8000529e:	b5fd                	j	8000518c <create+0x76>

00000000800052a0 <sys_dup>:
{
    800052a0:	7179                	addi	sp,sp,-48
    800052a2:	f406                	sd	ra,40(sp)
    800052a4:	f022                	sd	s0,32(sp)
    800052a6:	ec26                	sd	s1,24(sp)
    800052a8:	e84a                	sd	s2,16(sp)
    800052aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052ac:	fd840613          	addi	a2,s0,-40
    800052b0:	4581                	li	a1,0
    800052b2:	4501                	li	a0,0
    800052b4:	00000097          	auipc	ra,0x0
    800052b8:	dc0080e7          	jalr	-576(ra) # 80005074 <argfd>
    return -1;
    800052bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052be:	02054363          	bltz	a0,800052e4 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052c2:	fd843903          	ld	s2,-40(s0)
    800052c6:	854a                	mv	a0,s2
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	e0c080e7          	jalr	-500(ra) # 800050d4 <fdalloc>
    800052d0:	84aa                	mv	s1,a0
    return -1;
    800052d2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052d4:	00054863          	bltz	a0,800052e4 <sys_dup+0x44>
  filedup(f);
    800052d8:	854a                	mv	a0,s2
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	310080e7          	jalr	784(ra) # 800045ea <filedup>
  return fd;
    800052e2:	87a6                	mv	a5,s1
}
    800052e4:	853e                	mv	a0,a5
    800052e6:	70a2                	ld	ra,40(sp)
    800052e8:	7402                	ld	s0,32(sp)
    800052ea:	64e2                	ld	s1,24(sp)
    800052ec:	6942                	ld	s2,16(sp)
    800052ee:	6145                	addi	sp,sp,48
    800052f0:	8082                	ret

00000000800052f2 <sys_read>:
{
    800052f2:	7179                	addi	sp,sp,-48
    800052f4:	f406                	sd	ra,40(sp)
    800052f6:	f022                	sd	s0,32(sp)
    800052f8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052fa:	fd840593          	addi	a1,s0,-40
    800052fe:	4505                	li	a0,1
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	88c080e7          	jalr	-1908(ra) # 80002b8c <argaddr>
  argint(2, &n);
    80005308:	fe440593          	addi	a1,s0,-28
    8000530c:	4509                	li	a0,2
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	85e080e7          	jalr	-1954(ra) # 80002b6c <argint>
  if(argfd(0, 0, &f) < 0)
    80005316:	fe840613          	addi	a2,s0,-24
    8000531a:	4581                	li	a1,0
    8000531c:	4501                	li	a0,0
    8000531e:	00000097          	auipc	ra,0x0
    80005322:	d56080e7          	jalr	-682(ra) # 80005074 <argfd>
    80005326:	87aa                	mv	a5,a0
    return -1;
    80005328:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000532a:	0007cc63          	bltz	a5,80005342 <sys_read+0x50>
  return fileread(f, p, n);
    8000532e:	fe442603          	lw	a2,-28(s0)
    80005332:	fd843583          	ld	a1,-40(s0)
    80005336:	fe843503          	ld	a0,-24(s0)
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	43c080e7          	jalr	1084(ra) # 80004776 <fileread>
}
    80005342:	70a2                	ld	ra,40(sp)
    80005344:	7402                	ld	s0,32(sp)
    80005346:	6145                	addi	sp,sp,48
    80005348:	8082                	ret

000000008000534a <sys_write>:
{
    8000534a:	7179                	addi	sp,sp,-48
    8000534c:	f406                	sd	ra,40(sp)
    8000534e:	f022                	sd	s0,32(sp)
    80005350:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005352:	fd840593          	addi	a1,s0,-40
    80005356:	4505                	li	a0,1
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	834080e7          	jalr	-1996(ra) # 80002b8c <argaddr>
  argint(2, &n);
    80005360:	fe440593          	addi	a1,s0,-28
    80005364:	4509                	li	a0,2
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	806080e7          	jalr	-2042(ra) # 80002b6c <argint>
  if(argfd(0, 0, &f) < 0)
    8000536e:	fe840613          	addi	a2,s0,-24
    80005372:	4581                	li	a1,0
    80005374:	4501                	li	a0,0
    80005376:	00000097          	auipc	ra,0x0
    8000537a:	cfe080e7          	jalr	-770(ra) # 80005074 <argfd>
    8000537e:	87aa                	mv	a5,a0
    return -1;
    80005380:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005382:	0007cc63          	bltz	a5,8000539a <sys_write+0x50>
  return filewrite(f, p, n);
    80005386:	fe442603          	lw	a2,-28(s0)
    8000538a:	fd843583          	ld	a1,-40(s0)
    8000538e:	fe843503          	ld	a0,-24(s0)
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	4a6080e7          	jalr	1190(ra) # 80004838 <filewrite>
}
    8000539a:	70a2                	ld	ra,40(sp)
    8000539c:	7402                	ld	s0,32(sp)
    8000539e:	6145                	addi	sp,sp,48
    800053a0:	8082                	ret

00000000800053a2 <sys_close>:
{
    800053a2:	1101                	addi	sp,sp,-32
    800053a4:	ec06                	sd	ra,24(sp)
    800053a6:	e822                	sd	s0,16(sp)
    800053a8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053aa:	fe040613          	addi	a2,s0,-32
    800053ae:	fec40593          	addi	a1,s0,-20
    800053b2:	4501                	li	a0,0
    800053b4:	00000097          	auipc	ra,0x0
    800053b8:	cc0080e7          	jalr	-832(ra) # 80005074 <argfd>
    return -1;
    800053bc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053be:	02054463          	bltz	a0,800053e6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053c2:	ffffc097          	auipc	ra,0xffffc
    800053c6:	5ea080e7          	jalr	1514(ra) # 800019ac <myproc>
    800053ca:	fec42783          	lw	a5,-20(s0)
    800053ce:	07e9                	addi	a5,a5,26
    800053d0:	078e                	slli	a5,a5,0x3
    800053d2:	953e                	add	a0,a0,a5
    800053d4:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053d8:	fe043503          	ld	a0,-32(s0)
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	260080e7          	jalr	608(ra) # 8000463c <fileclose>
  return 0;
    800053e4:	4781                	li	a5,0
}
    800053e6:	853e                	mv	a0,a5
    800053e8:	60e2                	ld	ra,24(sp)
    800053ea:	6442                	ld	s0,16(sp)
    800053ec:	6105                	addi	sp,sp,32
    800053ee:	8082                	ret

00000000800053f0 <sys_fstat>:
{
    800053f0:	1101                	addi	sp,sp,-32
    800053f2:	ec06                	sd	ra,24(sp)
    800053f4:	e822                	sd	s0,16(sp)
    800053f6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053f8:	fe040593          	addi	a1,s0,-32
    800053fc:	4505                	li	a0,1
    800053fe:	ffffd097          	auipc	ra,0xffffd
    80005402:	78e080e7          	jalr	1934(ra) # 80002b8c <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005406:	fe840613          	addi	a2,s0,-24
    8000540a:	4581                	li	a1,0
    8000540c:	4501                	li	a0,0
    8000540e:	00000097          	auipc	ra,0x0
    80005412:	c66080e7          	jalr	-922(ra) # 80005074 <argfd>
    80005416:	87aa                	mv	a5,a0
    return -1;
    80005418:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000541a:	0007ca63          	bltz	a5,8000542e <sys_fstat+0x3e>
  return filestat(f, st);
    8000541e:	fe043583          	ld	a1,-32(s0)
    80005422:	fe843503          	ld	a0,-24(s0)
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	2de080e7          	jalr	734(ra) # 80004704 <filestat>
}
    8000542e:	60e2                	ld	ra,24(sp)
    80005430:	6442                	ld	s0,16(sp)
    80005432:	6105                	addi	sp,sp,32
    80005434:	8082                	ret

0000000080005436 <sys_link>:
{
    80005436:	7169                	addi	sp,sp,-304
    80005438:	f606                	sd	ra,296(sp)
    8000543a:	f222                	sd	s0,288(sp)
    8000543c:	ee26                	sd	s1,280(sp)
    8000543e:	ea4a                	sd	s2,272(sp)
    80005440:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005442:	08000613          	li	a2,128
    80005446:	ed040593          	addi	a1,s0,-304
    8000544a:	4501                	li	a0,0
    8000544c:	ffffd097          	auipc	ra,0xffffd
    80005450:	760080e7          	jalr	1888(ra) # 80002bac <argstr>
    return -1;
    80005454:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005456:	10054e63          	bltz	a0,80005572 <sys_link+0x13c>
    8000545a:	08000613          	li	a2,128
    8000545e:	f5040593          	addi	a1,s0,-176
    80005462:	4505                	li	a0,1
    80005464:	ffffd097          	auipc	ra,0xffffd
    80005468:	748080e7          	jalr	1864(ra) # 80002bac <argstr>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000546e:	10054263          	bltz	a0,80005572 <sys_link+0x13c>
  begin_op();
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	d02080e7          	jalr	-766(ra) # 80004174 <begin_op>
  if((ip = namei(old)) == 0){
    8000547a:	ed040513          	addi	a0,s0,-304
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	ad6080e7          	jalr	-1322(ra) # 80003f54 <namei>
    80005486:	84aa                	mv	s1,a0
    80005488:	c551                	beqz	a0,80005514 <sys_link+0xde>
  ilock(ip);
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	31e080e7          	jalr	798(ra) # 800037a8 <ilock>
  if(ip->type == T_DIR){
    80005492:	04449703          	lh	a4,68(s1)
    80005496:	4785                	li	a5,1
    80005498:	08f70463          	beq	a4,a5,80005520 <sys_link+0xea>
  ip->nlink++;
    8000549c:	04a4d783          	lhu	a5,74(s1)
    800054a0:	2785                	addiw	a5,a5,1
    800054a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a6:	8526                	mv	a0,s1
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	234080e7          	jalr	564(ra) # 800036dc <iupdate>
  iunlock(ip);
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	3b8080e7          	jalr	952(ra) # 8000386a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054ba:	fd040593          	addi	a1,s0,-48
    800054be:	f5040513          	addi	a0,s0,-176
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	ab0080e7          	jalr	-1360(ra) # 80003f72 <nameiparent>
    800054ca:	892a                	mv	s2,a0
    800054cc:	c935                	beqz	a0,80005540 <sys_link+0x10a>
  ilock(dp);
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	2da080e7          	jalr	730(ra) # 800037a8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054d6:	00092703          	lw	a4,0(s2)
    800054da:	409c                	lw	a5,0(s1)
    800054dc:	04f71d63          	bne	a4,a5,80005536 <sys_link+0x100>
    800054e0:	40d0                	lw	a2,4(s1)
    800054e2:	fd040593          	addi	a1,s0,-48
    800054e6:	854a                	mv	a0,s2
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	9ba080e7          	jalr	-1606(ra) # 80003ea2 <dirlink>
    800054f0:	04054363          	bltz	a0,80005536 <sys_link+0x100>
  iunlockput(dp);
    800054f4:	854a                	mv	a0,s2
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	514080e7          	jalr	1300(ra) # 80003a0a <iunlockput>
  iput(ip);
    800054fe:	8526                	mv	a0,s1
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	462080e7          	jalr	1122(ra) # 80003962 <iput>
  end_op();
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	cea080e7          	jalr	-790(ra) # 800041f2 <end_op>
  return 0;
    80005510:	4781                	li	a5,0
    80005512:	a085                	j	80005572 <sys_link+0x13c>
    end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	cde080e7          	jalr	-802(ra) # 800041f2 <end_op>
    return -1;
    8000551c:	57fd                	li	a5,-1
    8000551e:	a891                	j	80005572 <sys_link+0x13c>
    iunlockput(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	4e8080e7          	jalr	1256(ra) # 80003a0a <iunlockput>
    end_op();
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	cc8080e7          	jalr	-824(ra) # 800041f2 <end_op>
    return -1;
    80005532:	57fd                	li	a5,-1
    80005534:	a83d                	j	80005572 <sys_link+0x13c>
    iunlockput(dp);
    80005536:	854a                	mv	a0,s2
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	4d2080e7          	jalr	1234(ra) # 80003a0a <iunlockput>
  ilock(ip);
    80005540:	8526                	mv	a0,s1
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	266080e7          	jalr	614(ra) # 800037a8 <ilock>
  ip->nlink--;
    8000554a:	04a4d783          	lhu	a5,74(s1)
    8000554e:	37fd                	addiw	a5,a5,-1
    80005550:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	186080e7          	jalr	390(ra) # 800036dc <iupdate>
  iunlockput(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	4aa080e7          	jalr	1194(ra) # 80003a0a <iunlockput>
  end_op();
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	c8a080e7          	jalr	-886(ra) # 800041f2 <end_op>
  return -1;
    80005570:	57fd                	li	a5,-1
}
    80005572:	853e                	mv	a0,a5
    80005574:	70b2                	ld	ra,296(sp)
    80005576:	7412                	ld	s0,288(sp)
    80005578:	64f2                	ld	s1,280(sp)
    8000557a:	6952                	ld	s2,272(sp)
    8000557c:	6155                	addi	sp,sp,304
    8000557e:	8082                	ret

0000000080005580 <sys_unlink>:
{
    80005580:	7151                	addi	sp,sp,-240
    80005582:	f586                	sd	ra,232(sp)
    80005584:	f1a2                	sd	s0,224(sp)
    80005586:	eda6                	sd	s1,216(sp)
    80005588:	e9ca                	sd	s2,208(sp)
    8000558a:	e5ce                	sd	s3,200(sp)
    8000558c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000558e:	08000613          	li	a2,128
    80005592:	f3040593          	addi	a1,s0,-208
    80005596:	4501                	li	a0,0
    80005598:	ffffd097          	auipc	ra,0xffffd
    8000559c:	614080e7          	jalr	1556(ra) # 80002bac <argstr>
    800055a0:	18054163          	bltz	a0,80005722 <sys_unlink+0x1a2>
  begin_op();
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	bd0080e7          	jalr	-1072(ra) # 80004174 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055ac:	fb040593          	addi	a1,s0,-80
    800055b0:	f3040513          	addi	a0,s0,-208
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	9be080e7          	jalr	-1602(ra) # 80003f72 <nameiparent>
    800055bc:	84aa                	mv	s1,a0
    800055be:	c979                	beqz	a0,80005694 <sys_unlink+0x114>
  ilock(dp);
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	1e8080e7          	jalr	488(ra) # 800037a8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055c8:	00003597          	auipc	a1,0x3
    800055cc:	14858593          	addi	a1,a1,328 # 80008710 <syscalls+0x2b8>
    800055d0:	fb040513          	addi	a0,s0,-80
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	69e080e7          	jalr	1694(ra) # 80003c72 <namecmp>
    800055dc:	14050a63          	beqz	a0,80005730 <sys_unlink+0x1b0>
    800055e0:	00003597          	auipc	a1,0x3
    800055e4:	13858593          	addi	a1,a1,312 # 80008718 <syscalls+0x2c0>
    800055e8:	fb040513          	addi	a0,s0,-80
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	686080e7          	jalr	1670(ra) # 80003c72 <namecmp>
    800055f4:	12050e63          	beqz	a0,80005730 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055f8:	f2c40613          	addi	a2,s0,-212
    800055fc:	fb040593          	addi	a1,s0,-80
    80005600:	8526                	mv	a0,s1
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	68a080e7          	jalr	1674(ra) # 80003c8c <dirlookup>
    8000560a:	892a                	mv	s2,a0
    8000560c:	12050263          	beqz	a0,80005730 <sys_unlink+0x1b0>
  ilock(ip);
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	198080e7          	jalr	408(ra) # 800037a8 <ilock>
  if(ip->nlink < 1)
    80005618:	04a91783          	lh	a5,74(s2)
    8000561c:	08f05263          	blez	a5,800056a0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005620:	04491703          	lh	a4,68(s2)
    80005624:	4785                	li	a5,1
    80005626:	08f70563          	beq	a4,a5,800056b0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000562a:	4641                	li	a2,16
    8000562c:	4581                	li	a1,0
    8000562e:	fc040513          	addi	a0,s0,-64
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	6a0080e7          	jalr	1696(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000563a:	4741                	li	a4,16
    8000563c:	f2c42683          	lw	a3,-212(s0)
    80005640:	fc040613          	addi	a2,s0,-64
    80005644:	4581                	li	a1,0
    80005646:	8526                	mv	a0,s1
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	50c080e7          	jalr	1292(ra) # 80003b54 <writei>
    80005650:	47c1                	li	a5,16
    80005652:	0af51563          	bne	a0,a5,800056fc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005656:	04491703          	lh	a4,68(s2)
    8000565a:	4785                	li	a5,1
    8000565c:	0af70863          	beq	a4,a5,8000570c <sys_unlink+0x18c>
  iunlockput(dp);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	3a8080e7          	jalr	936(ra) # 80003a0a <iunlockput>
  ip->nlink--;
    8000566a:	04a95783          	lhu	a5,74(s2)
    8000566e:	37fd                	addiw	a5,a5,-1
    80005670:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005674:	854a                	mv	a0,s2
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	066080e7          	jalr	102(ra) # 800036dc <iupdate>
  iunlockput(ip);
    8000567e:	854a                	mv	a0,s2
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	38a080e7          	jalr	906(ra) # 80003a0a <iunlockput>
  end_op();
    80005688:	fffff097          	auipc	ra,0xfffff
    8000568c:	b6a080e7          	jalr	-1174(ra) # 800041f2 <end_op>
  return 0;
    80005690:	4501                	li	a0,0
    80005692:	a84d                	j	80005744 <sys_unlink+0x1c4>
    end_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	b5e080e7          	jalr	-1186(ra) # 800041f2 <end_op>
    return -1;
    8000569c:	557d                	li	a0,-1
    8000569e:	a05d                	j	80005744 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056a0:	00003517          	auipc	a0,0x3
    800056a4:	08050513          	addi	a0,a0,128 # 80008720 <syscalls+0x2c8>
    800056a8:	ffffb097          	auipc	ra,0xffffb
    800056ac:	e98080e7          	jalr	-360(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b0:	04c92703          	lw	a4,76(s2)
    800056b4:	02000793          	li	a5,32
    800056b8:	f6e7f9e3          	bgeu	a5,a4,8000562a <sys_unlink+0xaa>
    800056bc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056c0:	4741                	li	a4,16
    800056c2:	86ce                	mv	a3,s3
    800056c4:	f1840613          	addi	a2,s0,-232
    800056c8:	4581                	li	a1,0
    800056ca:	854a                	mv	a0,s2
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	390080e7          	jalr	912(ra) # 80003a5c <readi>
    800056d4:	47c1                	li	a5,16
    800056d6:	00f51b63          	bne	a0,a5,800056ec <sys_unlink+0x16c>
    if(de.inum != 0)
    800056da:	f1845783          	lhu	a5,-232(s0)
    800056de:	e7a1                	bnez	a5,80005726 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e0:	29c1                	addiw	s3,s3,16
    800056e2:	04c92783          	lw	a5,76(s2)
    800056e6:	fcf9ede3          	bltu	s3,a5,800056c0 <sys_unlink+0x140>
    800056ea:	b781                	j	8000562a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056ec:	00003517          	auipc	a0,0x3
    800056f0:	04c50513          	addi	a0,a0,76 # 80008738 <syscalls+0x2e0>
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	e4c080e7          	jalr	-436(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056fc:	00003517          	auipc	a0,0x3
    80005700:	05450513          	addi	a0,a0,84 # 80008750 <syscalls+0x2f8>
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	e3c080e7          	jalr	-452(ra) # 80000540 <panic>
    dp->nlink--;
    8000570c:	04a4d783          	lhu	a5,74(s1)
    80005710:	37fd                	addiw	a5,a5,-1
    80005712:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005716:	8526                	mv	a0,s1
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	fc4080e7          	jalr	-60(ra) # 800036dc <iupdate>
    80005720:	b781                	j	80005660 <sys_unlink+0xe0>
    return -1;
    80005722:	557d                	li	a0,-1
    80005724:	a005                	j	80005744 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005726:	854a                	mv	a0,s2
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	2e2080e7          	jalr	738(ra) # 80003a0a <iunlockput>
  iunlockput(dp);
    80005730:	8526                	mv	a0,s1
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	2d8080e7          	jalr	728(ra) # 80003a0a <iunlockput>
  end_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	ab8080e7          	jalr	-1352(ra) # 800041f2 <end_op>
  return -1;
    80005742:	557d                	li	a0,-1
}
    80005744:	70ae                	ld	ra,232(sp)
    80005746:	740e                	ld	s0,224(sp)
    80005748:	64ee                	ld	s1,216(sp)
    8000574a:	694e                	ld	s2,208(sp)
    8000574c:	69ae                	ld	s3,200(sp)
    8000574e:	616d                	addi	sp,sp,240
    80005750:	8082                	ret

0000000080005752 <sys_open>:

uint64
sys_open(void)
{
    80005752:	7131                	addi	sp,sp,-192
    80005754:	fd06                	sd	ra,184(sp)
    80005756:	f922                	sd	s0,176(sp)
    80005758:	f526                	sd	s1,168(sp)
    8000575a:	f14a                	sd	s2,160(sp)
    8000575c:	ed4e                	sd	s3,152(sp)
    8000575e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005760:	f4c40593          	addi	a1,s0,-180
    80005764:	4505                	li	a0,1
    80005766:	ffffd097          	auipc	ra,0xffffd
    8000576a:	406080e7          	jalr	1030(ra) # 80002b6c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000576e:	08000613          	li	a2,128
    80005772:	f5040593          	addi	a1,s0,-176
    80005776:	4501                	li	a0,0
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	434080e7          	jalr	1076(ra) # 80002bac <argstr>
    80005780:	87aa                	mv	a5,a0
    return -1;
    80005782:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005784:	0a07c963          	bltz	a5,80005836 <sys_open+0xe4>

  begin_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	9ec080e7          	jalr	-1556(ra) # 80004174 <begin_op>

  if(omode & O_CREATE){
    80005790:	f4c42783          	lw	a5,-180(s0)
    80005794:	2007f793          	andi	a5,a5,512
    80005798:	cfc5                	beqz	a5,80005850 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000579a:	4681                	li	a3,0
    8000579c:	4601                	li	a2,0
    8000579e:	4589                	li	a1,2
    800057a0:	f5040513          	addi	a0,s0,-176
    800057a4:	00000097          	auipc	ra,0x0
    800057a8:	972080e7          	jalr	-1678(ra) # 80005116 <create>
    800057ac:	84aa                	mv	s1,a0
    if(ip == 0){
    800057ae:	c959                	beqz	a0,80005844 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057b0:	04449703          	lh	a4,68(s1)
    800057b4:	478d                	li	a5,3
    800057b6:	00f71763          	bne	a4,a5,800057c4 <sys_open+0x72>
    800057ba:	0464d703          	lhu	a4,70(s1)
    800057be:	47a5                	li	a5,9
    800057c0:	0ce7ed63          	bltu	a5,a4,8000589a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	dbc080e7          	jalr	-580(ra) # 80004580 <filealloc>
    800057cc:	89aa                	mv	s3,a0
    800057ce:	10050363          	beqz	a0,800058d4 <sys_open+0x182>
    800057d2:	00000097          	auipc	ra,0x0
    800057d6:	902080e7          	jalr	-1790(ra) # 800050d4 <fdalloc>
    800057da:	892a                	mv	s2,a0
    800057dc:	0e054763          	bltz	a0,800058ca <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057e0:	04449703          	lh	a4,68(s1)
    800057e4:	478d                	li	a5,3
    800057e6:	0cf70563          	beq	a4,a5,800058b0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057ea:	4789                	li	a5,2
    800057ec:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057f0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057f4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057f8:	f4c42783          	lw	a5,-180(s0)
    800057fc:	0017c713          	xori	a4,a5,1
    80005800:	8b05                	andi	a4,a4,1
    80005802:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005806:	0037f713          	andi	a4,a5,3
    8000580a:	00e03733          	snez	a4,a4
    8000580e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005812:	4007f793          	andi	a5,a5,1024
    80005816:	c791                	beqz	a5,80005822 <sys_open+0xd0>
    80005818:	04449703          	lh	a4,68(s1)
    8000581c:	4789                	li	a5,2
    8000581e:	0af70063          	beq	a4,a5,800058be <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	046080e7          	jalr	70(ra) # 8000386a <iunlock>
  end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	9c6080e7          	jalr	-1594(ra) # 800041f2 <end_op>

  return fd;
    80005834:	854a                	mv	a0,s2
}
    80005836:	70ea                	ld	ra,184(sp)
    80005838:	744a                	ld	s0,176(sp)
    8000583a:	74aa                	ld	s1,168(sp)
    8000583c:	790a                	ld	s2,160(sp)
    8000583e:	69ea                	ld	s3,152(sp)
    80005840:	6129                	addi	sp,sp,192
    80005842:	8082                	ret
      end_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	9ae080e7          	jalr	-1618(ra) # 800041f2 <end_op>
      return -1;
    8000584c:	557d                	li	a0,-1
    8000584e:	b7e5                	j	80005836 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005850:	f5040513          	addi	a0,s0,-176
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	700080e7          	jalr	1792(ra) # 80003f54 <namei>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	c905                	beqz	a0,8000588e <sys_open+0x13c>
    ilock(ip);
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	f48080e7          	jalr	-184(ra) # 800037a8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005868:	04449703          	lh	a4,68(s1)
    8000586c:	4785                	li	a5,1
    8000586e:	f4f711e3          	bne	a4,a5,800057b0 <sys_open+0x5e>
    80005872:	f4c42783          	lw	a5,-180(s0)
    80005876:	d7b9                	beqz	a5,800057c4 <sys_open+0x72>
      iunlockput(ip);
    80005878:	8526                	mv	a0,s1
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	190080e7          	jalr	400(ra) # 80003a0a <iunlockput>
      end_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	970080e7          	jalr	-1680(ra) # 800041f2 <end_op>
      return -1;
    8000588a:	557d                	li	a0,-1
    8000588c:	b76d                	j	80005836 <sys_open+0xe4>
      end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	964080e7          	jalr	-1692(ra) # 800041f2 <end_op>
      return -1;
    80005896:	557d                	li	a0,-1
    80005898:	bf79                	j	80005836 <sys_open+0xe4>
    iunlockput(ip);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	16e080e7          	jalr	366(ra) # 80003a0a <iunlockput>
    end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	94e080e7          	jalr	-1714(ra) # 800041f2 <end_op>
    return -1;
    800058ac:	557d                	li	a0,-1
    800058ae:	b761                	j	80005836 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058b0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058b4:	04649783          	lh	a5,70(s1)
    800058b8:	02f99223          	sh	a5,36(s3)
    800058bc:	bf25                	j	800057f4 <sys_open+0xa2>
    itrunc(ip);
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	ff6080e7          	jalr	-10(ra) # 800038b6 <itrunc>
    800058c8:	bfa9                	j	80005822 <sys_open+0xd0>
      fileclose(f);
    800058ca:	854e                	mv	a0,s3
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	d70080e7          	jalr	-656(ra) # 8000463c <fileclose>
    iunlockput(ip);
    800058d4:	8526                	mv	a0,s1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	134080e7          	jalr	308(ra) # 80003a0a <iunlockput>
    end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	914080e7          	jalr	-1772(ra) # 800041f2 <end_op>
    return -1;
    800058e6:	557d                	li	a0,-1
    800058e8:	b7b9                	j	80005836 <sys_open+0xe4>

00000000800058ea <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058ea:	7175                	addi	sp,sp,-144
    800058ec:	e506                	sd	ra,136(sp)
    800058ee:	e122                	sd	s0,128(sp)
    800058f0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	882080e7          	jalr	-1918(ra) # 80004174 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058fa:	08000613          	li	a2,128
    800058fe:	f7040593          	addi	a1,s0,-144
    80005902:	4501                	li	a0,0
    80005904:	ffffd097          	auipc	ra,0xffffd
    80005908:	2a8080e7          	jalr	680(ra) # 80002bac <argstr>
    8000590c:	02054963          	bltz	a0,8000593e <sys_mkdir+0x54>
    80005910:	4681                	li	a3,0
    80005912:	4601                	li	a2,0
    80005914:	4585                	li	a1,1
    80005916:	f7040513          	addi	a0,s0,-144
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	7fc080e7          	jalr	2044(ra) # 80005116 <create>
    80005922:	cd11                	beqz	a0,8000593e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	0e6080e7          	jalr	230(ra) # 80003a0a <iunlockput>
  end_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	8c6080e7          	jalr	-1850(ra) # 800041f2 <end_op>
  return 0;
    80005934:	4501                	li	a0,0
}
    80005936:	60aa                	ld	ra,136(sp)
    80005938:	640a                	ld	s0,128(sp)
    8000593a:	6149                	addi	sp,sp,144
    8000593c:	8082                	ret
    end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	8b4080e7          	jalr	-1868(ra) # 800041f2 <end_op>
    return -1;
    80005946:	557d                	li	a0,-1
    80005948:	b7fd                	j	80005936 <sys_mkdir+0x4c>

000000008000594a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000594a:	7135                	addi	sp,sp,-160
    8000594c:	ed06                	sd	ra,152(sp)
    8000594e:	e922                	sd	s0,144(sp)
    80005950:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	822080e7          	jalr	-2014(ra) # 80004174 <begin_op>
  argint(1, &major);
    8000595a:	f6c40593          	addi	a1,s0,-148
    8000595e:	4505                	li	a0,1
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	20c080e7          	jalr	524(ra) # 80002b6c <argint>
  argint(2, &minor);
    80005968:	f6840593          	addi	a1,s0,-152
    8000596c:	4509                	li	a0,2
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	1fe080e7          	jalr	510(ra) # 80002b6c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005976:	08000613          	li	a2,128
    8000597a:	f7040593          	addi	a1,s0,-144
    8000597e:	4501                	li	a0,0
    80005980:	ffffd097          	auipc	ra,0xffffd
    80005984:	22c080e7          	jalr	556(ra) # 80002bac <argstr>
    80005988:	02054b63          	bltz	a0,800059be <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000598c:	f6841683          	lh	a3,-152(s0)
    80005990:	f6c41603          	lh	a2,-148(s0)
    80005994:	458d                	li	a1,3
    80005996:	f7040513          	addi	a0,s0,-144
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	77c080e7          	jalr	1916(ra) # 80005116 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a2:	cd11                	beqz	a0,800059be <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	066080e7          	jalr	102(ra) # 80003a0a <iunlockput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	846080e7          	jalr	-1978(ra) # 800041f2 <end_op>
  return 0;
    800059b4:	4501                	li	a0,0
}
    800059b6:	60ea                	ld	ra,152(sp)
    800059b8:	644a                	ld	s0,144(sp)
    800059ba:	610d                	addi	sp,sp,160
    800059bc:	8082                	ret
    end_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	834080e7          	jalr	-1996(ra) # 800041f2 <end_op>
    return -1;
    800059c6:	557d                	li	a0,-1
    800059c8:	b7fd                	j	800059b6 <sys_mknod+0x6c>

00000000800059ca <sys_chdir>:

uint64
sys_chdir(void)
{
    800059ca:	7135                	addi	sp,sp,-160
    800059cc:	ed06                	sd	ra,152(sp)
    800059ce:	e922                	sd	s0,144(sp)
    800059d0:	e526                	sd	s1,136(sp)
    800059d2:	e14a                	sd	s2,128(sp)
    800059d4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059d6:	ffffc097          	auipc	ra,0xffffc
    800059da:	fd6080e7          	jalr	-42(ra) # 800019ac <myproc>
    800059de:	892a                	mv	s2,a0
  
  begin_op();
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	794080e7          	jalr	1940(ra) # 80004174 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059e8:	08000613          	li	a2,128
    800059ec:	f6040593          	addi	a1,s0,-160
    800059f0:	4501                	li	a0,0
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	1ba080e7          	jalr	442(ra) # 80002bac <argstr>
    800059fa:	04054b63          	bltz	a0,80005a50 <sys_chdir+0x86>
    800059fe:	f6040513          	addi	a0,s0,-160
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	552080e7          	jalr	1362(ra) # 80003f54 <namei>
    80005a0a:	84aa                	mv	s1,a0
    80005a0c:	c131                	beqz	a0,80005a50 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	d9a080e7          	jalr	-614(ra) # 800037a8 <ilock>
  if(ip->type != T_DIR){
    80005a16:	04449703          	lh	a4,68(s1)
    80005a1a:	4785                	li	a5,1
    80005a1c:	04f71063          	bne	a4,a5,80005a5c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a20:	8526                	mv	a0,s1
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	e48080e7          	jalr	-440(ra) # 8000386a <iunlock>
  iput(p->cwd);
    80005a2a:	15093503          	ld	a0,336(s2)
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	f34080e7          	jalr	-204(ra) # 80003962 <iput>
  end_op();
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	7bc080e7          	jalr	1980(ra) # 800041f2 <end_op>
  p->cwd = ip;
    80005a3e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a42:	4501                	li	a0,0
}
    80005a44:	60ea                	ld	ra,152(sp)
    80005a46:	644a                	ld	s0,144(sp)
    80005a48:	64aa                	ld	s1,136(sp)
    80005a4a:	690a                	ld	s2,128(sp)
    80005a4c:	610d                	addi	sp,sp,160
    80005a4e:	8082                	ret
    end_op();
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	7a2080e7          	jalr	1954(ra) # 800041f2 <end_op>
    return -1;
    80005a58:	557d                	li	a0,-1
    80005a5a:	b7ed                	j	80005a44 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a5c:	8526                	mv	a0,s1
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	fac080e7          	jalr	-84(ra) # 80003a0a <iunlockput>
    end_op();
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	78c080e7          	jalr	1932(ra) # 800041f2 <end_op>
    return -1;
    80005a6e:	557d                	li	a0,-1
    80005a70:	bfd1                	j	80005a44 <sys_chdir+0x7a>

0000000080005a72 <sys_exec>:

uint64
sys_exec(void)
{
    80005a72:	7145                	addi	sp,sp,-464
    80005a74:	e786                	sd	ra,456(sp)
    80005a76:	e3a2                	sd	s0,448(sp)
    80005a78:	ff26                	sd	s1,440(sp)
    80005a7a:	fb4a                	sd	s2,432(sp)
    80005a7c:	f74e                	sd	s3,424(sp)
    80005a7e:	f352                	sd	s4,416(sp)
    80005a80:	ef56                	sd	s5,408(sp)
    80005a82:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a84:	e3840593          	addi	a1,s0,-456
    80005a88:	4505                	li	a0,1
    80005a8a:	ffffd097          	auipc	ra,0xffffd
    80005a8e:	102080e7          	jalr	258(ra) # 80002b8c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a92:	08000613          	li	a2,128
    80005a96:	f4040593          	addi	a1,s0,-192
    80005a9a:	4501                	li	a0,0
    80005a9c:	ffffd097          	auipc	ra,0xffffd
    80005aa0:	110080e7          	jalr	272(ra) # 80002bac <argstr>
    80005aa4:	87aa                	mv	a5,a0
    return -1;
    80005aa6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005aa8:	0c07c363          	bltz	a5,80005b6e <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005aac:	10000613          	li	a2,256
    80005ab0:	4581                	li	a1,0
    80005ab2:	e4040513          	addi	a0,s0,-448
    80005ab6:	ffffb097          	auipc	ra,0xffffb
    80005aba:	21c080e7          	jalr	540(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005abe:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ac2:	89a6                	mv	s3,s1
    80005ac4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ac6:	02000a13          	li	s4,32
    80005aca:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ace:	00391513          	slli	a0,s2,0x3
    80005ad2:	e3040593          	addi	a1,s0,-464
    80005ad6:	e3843783          	ld	a5,-456(s0)
    80005ada:	953e                	add	a0,a0,a5
    80005adc:	ffffd097          	auipc	ra,0xffffd
    80005ae0:	ff2080e7          	jalr	-14(ra) # 80002ace <fetchaddr>
    80005ae4:	02054a63          	bltz	a0,80005b18 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ae8:	e3043783          	ld	a5,-464(s0)
    80005aec:	c3b9                	beqz	a5,80005b32 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	ff8080e7          	jalr	-8(ra) # 80000ae6 <kalloc>
    80005af6:	85aa                	mv	a1,a0
    80005af8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005afc:	cd11                	beqz	a0,80005b18 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005afe:	6605                	lui	a2,0x1
    80005b00:	e3043503          	ld	a0,-464(s0)
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	01c080e7          	jalr	28(ra) # 80002b20 <fetchstr>
    80005b0c:	00054663          	bltz	a0,80005b18 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b10:	0905                	addi	s2,s2,1
    80005b12:	09a1                	addi	s3,s3,8
    80005b14:	fb491be3          	bne	s2,s4,80005aca <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b18:	f4040913          	addi	s2,s0,-192
    80005b1c:	6088                	ld	a0,0(s1)
    80005b1e:	c539                	beqz	a0,80005b6c <sys_exec+0xfa>
    kfree(argv[i]);
    80005b20:	ffffb097          	auipc	ra,0xffffb
    80005b24:	ec8080e7          	jalr	-312(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b28:	04a1                	addi	s1,s1,8
    80005b2a:	ff2499e3          	bne	s1,s2,80005b1c <sys_exec+0xaa>
  return -1;
    80005b2e:	557d                	li	a0,-1
    80005b30:	a83d                	j	80005b6e <sys_exec+0xfc>
      argv[i] = 0;
    80005b32:	0a8e                	slli	s5,s5,0x3
    80005b34:	fc0a8793          	addi	a5,s5,-64
    80005b38:	00878ab3          	add	s5,a5,s0
    80005b3c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b40:	e4040593          	addi	a1,s0,-448
    80005b44:	f4040513          	addi	a0,s0,-192
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	16e080e7          	jalr	366(ra) # 80004cb6 <exec>
    80005b50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b52:	f4040993          	addi	s3,s0,-192
    80005b56:	6088                	ld	a0,0(s1)
    80005b58:	c901                	beqz	a0,80005b68 <sys_exec+0xf6>
    kfree(argv[i]);
    80005b5a:	ffffb097          	auipc	ra,0xffffb
    80005b5e:	e8e080e7          	jalr	-370(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b62:	04a1                	addi	s1,s1,8
    80005b64:	ff3499e3          	bne	s1,s3,80005b56 <sys_exec+0xe4>
  return ret;
    80005b68:	854a                	mv	a0,s2
    80005b6a:	a011                	j	80005b6e <sys_exec+0xfc>
  return -1;
    80005b6c:	557d                	li	a0,-1
}
    80005b6e:	60be                	ld	ra,456(sp)
    80005b70:	641e                	ld	s0,448(sp)
    80005b72:	74fa                	ld	s1,440(sp)
    80005b74:	795a                	ld	s2,432(sp)
    80005b76:	79ba                	ld	s3,424(sp)
    80005b78:	7a1a                	ld	s4,416(sp)
    80005b7a:	6afa                	ld	s5,408(sp)
    80005b7c:	6179                	addi	sp,sp,464
    80005b7e:	8082                	ret

0000000080005b80 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b80:	7139                	addi	sp,sp,-64
    80005b82:	fc06                	sd	ra,56(sp)
    80005b84:	f822                	sd	s0,48(sp)
    80005b86:	f426                	sd	s1,40(sp)
    80005b88:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b8a:	ffffc097          	auipc	ra,0xffffc
    80005b8e:	e22080e7          	jalr	-478(ra) # 800019ac <myproc>
    80005b92:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b94:	fd840593          	addi	a1,s0,-40
    80005b98:	4501                	li	a0,0
    80005b9a:	ffffd097          	auipc	ra,0xffffd
    80005b9e:	ff2080e7          	jalr	-14(ra) # 80002b8c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ba2:	fc840593          	addi	a1,s0,-56
    80005ba6:	fd040513          	addi	a0,s0,-48
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	dc2080e7          	jalr	-574(ra) # 8000496c <pipealloc>
    return -1;
    80005bb2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bb4:	0c054463          	bltz	a0,80005c7c <sys_pipe+0xfc>
  fd0 = -1;
    80005bb8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bbc:	fd043503          	ld	a0,-48(s0)
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	514080e7          	jalr	1300(ra) # 800050d4 <fdalloc>
    80005bc8:	fca42223          	sw	a0,-60(s0)
    80005bcc:	08054b63          	bltz	a0,80005c62 <sys_pipe+0xe2>
    80005bd0:	fc843503          	ld	a0,-56(s0)
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	500080e7          	jalr	1280(ra) # 800050d4 <fdalloc>
    80005bdc:	fca42023          	sw	a0,-64(s0)
    80005be0:	06054863          	bltz	a0,80005c50 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be4:	4691                	li	a3,4
    80005be6:	fc440613          	addi	a2,s0,-60
    80005bea:	fd843583          	ld	a1,-40(s0)
    80005bee:	68a8                	ld	a0,80(s1)
    80005bf0:	ffffc097          	auipc	ra,0xffffc
    80005bf4:	a7c080e7          	jalr	-1412(ra) # 8000166c <copyout>
    80005bf8:	02054063          	bltz	a0,80005c18 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bfc:	4691                	li	a3,4
    80005bfe:	fc040613          	addi	a2,s0,-64
    80005c02:	fd843583          	ld	a1,-40(s0)
    80005c06:	0591                	addi	a1,a1,4
    80005c08:	68a8                	ld	a0,80(s1)
    80005c0a:	ffffc097          	auipc	ra,0xffffc
    80005c0e:	a62080e7          	jalr	-1438(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c12:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c14:	06055463          	bgez	a0,80005c7c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c18:	fc442783          	lw	a5,-60(s0)
    80005c1c:	07e9                	addi	a5,a5,26
    80005c1e:	078e                	slli	a5,a5,0x3
    80005c20:	97a6                	add	a5,a5,s1
    80005c22:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c26:	fc042783          	lw	a5,-64(s0)
    80005c2a:	07e9                	addi	a5,a5,26
    80005c2c:	078e                	slli	a5,a5,0x3
    80005c2e:	94be                	add	s1,s1,a5
    80005c30:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c34:	fd043503          	ld	a0,-48(s0)
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	a04080e7          	jalr	-1532(ra) # 8000463c <fileclose>
    fileclose(wf);
    80005c40:	fc843503          	ld	a0,-56(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	9f8080e7          	jalr	-1544(ra) # 8000463c <fileclose>
    return -1;
    80005c4c:	57fd                	li	a5,-1
    80005c4e:	a03d                	j	80005c7c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c50:	fc442783          	lw	a5,-60(s0)
    80005c54:	0007c763          	bltz	a5,80005c62 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c58:	07e9                	addi	a5,a5,26
    80005c5a:	078e                	slli	a5,a5,0x3
    80005c5c:	97a6                	add	a5,a5,s1
    80005c5e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c62:	fd043503          	ld	a0,-48(s0)
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	9d6080e7          	jalr	-1578(ra) # 8000463c <fileclose>
    fileclose(wf);
    80005c6e:	fc843503          	ld	a0,-56(s0)
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	9ca080e7          	jalr	-1590(ra) # 8000463c <fileclose>
    return -1;
    80005c7a:	57fd                	li	a5,-1
}
    80005c7c:	853e                	mv	a0,a5
    80005c7e:	70e2                	ld	ra,56(sp)
    80005c80:	7442                	ld	s0,48(sp)
    80005c82:	74a2                	ld	s1,40(sp)
    80005c84:	6121                	addi	sp,sp,64
    80005c86:	8082                	ret
	...

0000000080005c90 <kernelvec>:
    80005c90:	7111                	addi	sp,sp,-256
    80005c92:	e006                	sd	ra,0(sp)
    80005c94:	e40a                	sd	sp,8(sp)
    80005c96:	e80e                	sd	gp,16(sp)
    80005c98:	ec12                	sd	tp,24(sp)
    80005c9a:	f016                	sd	t0,32(sp)
    80005c9c:	f41a                	sd	t1,40(sp)
    80005c9e:	f81e                	sd	t2,48(sp)
    80005ca0:	fc22                	sd	s0,56(sp)
    80005ca2:	e0a6                	sd	s1,64(sp)
    80005ca4:	e4aa                	sd	a0,72(sp)
    80005ca6:	e8ae                	sd	a1,80(sp)
    80005ca8:	ecb2                	sd	a2,88(sp)
    80005caa:	f0b6                	sd	a3,96(sp)
    80005cac:	f4ba                	sd	a4,104(sp)
    80005cae:	f8be                	sd	a5,112(sp)
    80005cb0:	fcc2                	sd	a6,120(sp)
    80005cb2:	e146                	sd	a7,128(sp)
    80005cb4:	e54a                	sd	s2,136(sp)
    80005cb6:	e94e                	sd	s3,144(sp)
    80005cb8:	ed52                	sd	s4,152(sp)
    80005cba:	f156                	sd	s5,160(sp)
    80005cbc:	f55a                	sd	s6,168(sp)
    80005cbe:	f95e                	sd	s7,176(sp)
    80005cc0:	fd62                	sd	s8,184(sp)
    80005cc2:	e1e6                	sd	s9,192(sp)
    80005cc4:	e5ea                	sd	s10,200(sp)
    80005cc6:	e9ee                	sd	s11,208(sp)
    80005cc8:	edf2                	sd	t3,216(sp)
    80005cca:	f1f6                	sd	t4,224(sp)
    80005ccc:	f5fa                	sd	t5,232(sp)
    80005cce:	f9fe                	sd	t6,240(sp)
    80005cd0:	ccbfc0ef          	jal	ra,8000299a <kerneltrap>
    80005cd4:	6082                	ld	ra,0(sp)
    80005cd6:	6122                	ld	sp,8(sp)
    80005cd8:	61c2                	ld	gp,16(sp)
    80005cda:	7282                	ld	t0,32(sp)
    80005cdc:	7322                	ld	t1,40(sp)
    80005cde:	73c2                	ld	t2,48(sp)
    80005ce0:	7462                	ld	s0,56(sp)
    80005ce2:	6486                	ld	s1,64(sp)
    80005ce4:	6526                	ld	a0,72(sp)
    80005ce6:	65c6                	ld	a1,80(sp)
    80005ce8:	6666                	ld	a2,88(sp)
    80005cea:	7686                	ld	a3,96(sp)
    80005cec:	7726                	ld	a4,104(sp)
    80005cee:	77c6                	ld	a5,112(sp)
    80005cf0:	7866                	ld	a6,120(sp)
    80005cf2:	688a                	ld	a7,128(sp)
    80005cf4:	692a                	ld	s2,136(sp)
    80005cf6:	69ca                	ld	s3,144(sp)
    80005cf8:	6a6a                	ld	s4,152(sp)
    80005cfa:	7a8a                	ld	s5,160(sp)
    80005cfc:	7b2a                	ld	s6,168(sp)
    80005cfe:	7bca                	ld	s7,176(sp)
    80005d00:	7c6a                	ld	s8,184(sp)
    80005d02:	6c8e                	ld	s9,192(sp)
    80005d04:	6d2e                	ld	s10,200(sp)
    80005d06:	6dce                	ld	s11,208(sp)
    80005d08:	6e6e                	ld	t3,216(sp)
    80005d0a:	7e8e                	ld	t4,224(sp)
    80005d0c:	7f2e                	ld	t5,232(sp)
    80005d0e:	7fce                	ld	t6,240(sp)
    80005d10:	6111                	addi	sp,sp,256
    80005d12:	10200073          	sret
    80005d16:	00000013          	nop
    80005d1a:	00000013          	nop
    80005d1e:	0001                	nop

0000000080005d20 <timervec>:
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	e10c                	sd	a1,0(a0)
    80005d26:	e510                	sd	a2,8(a0)
    80005d28:	e914                	sd	a3,16(a0)
    80005d2a:	6d0c                	ld	a1,24(a0)
    80005d2c:	7110                	ld	a2,32(a0)
    80005d2e:	6194                	ld	a3,0(a1)
    80005d30:	96b2                	add	a3,a3,a2
    80005d32:	e194                	sd	a3,0(a1)
    80005d34:	4589                	li	a1,2
    80005d36:	14459073          	csrw	sip,a1
    80005d3a:	6914                	ld	a3,16(a0)
    80005d3c:	6510                	ld	a2,8(a0)
    80005d3e:	610c                	ld	a1,0(a0)
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	30200073          	mret
	...

0000000080005d4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d4a:	1141                	addi	sp,sp,-16
    80005d4c:	e422                	sd	s0,8(sp)
    80005d4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d50:	0c0007b7          	lui	a5,0xc000
    80005d54:	4705                	li	a4,1
    80005d56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d58:	c3d8                	sw	a4,4(a5)
}
    80005d5a:	6422                	ld	s0,8(sp)
    80005d5c:	0141                	addi	sp,sp,16
    80005d5e:	8082                	ret

0000000080005d60 <plicinithart>:

void
plicinithart(void)
{
    80005d60:	1141                	addi	sp,sp,-16
    80005d62:	e406                	sd	ra,8(sp)
    80005d64:	e022                	sd	s0,0(sp)
    80005d66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c18080e7          	jalr	-1000(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d70:	0085171b          	slliw	a4,a0,0x8
    80005d74:	0c0027b7          	lui	a5,0xc002
    80005d78:	97ba                	add	a5,a5,a4
    80005d7a:	40200713          	li	a4,1026
    80005d7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d82:	00d5151b          	slliw	a0,a0,0xd
    80005d86:	0c2017b7          	lui	a5,0xc201
    80005d8a:	97aa                	add	a5,a5,a0
    80005d8c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d90:	60a2                	ld	ra,8(sp)
    80005d92:	6402                	ld	s0,0(sp)
    80005d94:	0141                	addi	sp,sp,16
    80005d96:	8082                	ret

0000000080005d98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d98:	1141                	addi	sp,sp,-16
    80005d9a:	e406                	sd	ra,8(sp)
    80005d9c:	e022                	sd	s0,0(sp)
    80005d9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da0:	ffffc097          	auipc	ra,0xffffc
    80005da4:	be0080e7          	jalr	-1056(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005da8:	00d5151b          	slliw	a0,a0,0xd
    80005dac:	0c2017b7          	lui	a5,0xc201
    80005db0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005db2:	43c8                	lw	a0,4(a5)
    80005db4:	60a2                	ld	ra,8(sp)
    80005db6:	6402                	ld	s0,0(sp)
    80005db8:	0141                	addi	sp,sp,16
    80005dba:	8082                	ret

0000000080005dbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dbc:	1101                	addi	sp,sp,-32
    80005dbe:	ec06                	sd	ra,24(sp)
    80005dc0:	e822                	sd	s0,16(sp)
    80005dc2:	e426                	sd	s1,8(sp)
    80005dc4:	1000                	addi	s0,sp,32
    80005dc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	bb8080e7          	jalr	-1096(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dd0:	00d5151b          	slliw	a0,a0,0xd
    80005dd4:	0c2017b7          	lui	a5,0xc201
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	c3c4                	sw	s1,4(a5)
}
    80005ddc:	60e2                	ld	ra,24(sp)
    80005dde:	6442                	ld	s0,16(sp)
    80005de0:	64a2                	ld	s1,8(sp)
    80005de2:	6105                	addi	sp,sp,32
    80005de4:	8082                	ret

0000000080005de6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005de6:	1141                	addi	sp,sp,-16
    80005de8:	e406                	sd	ra,8(sp)
    80005dea:	e022                	sd	s0,0(sp)
    80005dec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dee:	479d                	li	a5,7
    80005df0:	04a7cc63          	blt	a5,a0,80005e48 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005df4:	00034797          	auipc	a5,0x34
    80005df8:	04c78793          	addi	a5,a5,76 # 80039e40 <disk>
    80005dfc:	97aa                	add	a5,a5,a0
    80005dfe:	0187c783          	lbu	a5,24(a5)
    80005e02:	ebb9                	bnez	a5,80005e58 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e04:	00451693          	slli	a3,a0,0x4
    80005e08:	00034797          	auipc	a5,0x34
    80005e0c:	03878793          	addi	a5,a5,56 # 80039e40 <disk>
    80005e10:	6398                	ld	a4,0(a5)
    80005e12:	9736                	add	a4,a4,a3
    80005e14:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e18:	6398                	ld	a4,0(a5)
    80005e1a:	9736                	add	a4,a4,a3
    80005e1c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e20:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e24:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e28:	97aa                	add	a5,a5,a0
    80005e2a:	4705                	li	a4,1
    80005e2c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e30:	00034517          	auipc	a0,0x34
    80005e34:	02850513          	addi	a0,a0,40 # 80039e58 <disk+0x18>
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	280080e7          	jalr	640(ra) # 800020b8 <wakeup>
}
    80005e40:	60a2                	ld	ra,8(sp)
    80005e42:	6402                	ld	s0,0(sp)
    80005e44:	0141                	addi	sp,sp,16
    80005e46:	8082                	ret
    panic("free_desc 1");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	91850513          	addi	a0,a0,-1768 # 80008760 <syscalls+0x308>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6f0080e7          	jalr	1776(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	91850513          	addi	a0,a0,-1768 # 80008770 <syscalls+0x318>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6e0080e7          	jalr	1760(ra) # 80000540 <panic>

0000000080005e68 <virtio_disk_init>:
{
    80005e68:	1101                	addi	sp,sp,-32
    80005e6a:	ec06                	sd	ra,24(sp)
    80005e6c:	e822                	sd	s0,16(sp)
    80005e6e:	e426                	sd	s1,8(sp)
    80005e70:	e04a                	sd	s2,0(sp)
    80005e72:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e74:	00003597          	auipc	a1,0x3
    80005e78:	90c58593          	addi	a1,a1,-1780 # 80008780 <syscalls+0x328>
    80005e7c:	00034517          	auipc	a0,0x34
    80005e80:	0ec50513          	addi	a0,a0,236 # 80039f68 <disk+0x128>
    80005e84:	ffffb097          	auipc	ra,0xffffb
    80005e88:	cc2080e7          	jalr	-830(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	4398                	lw	a4,0(a5)
    80005e92:	2701                	sext.w	a4,a4
    80005e94:	747277b7          	lui	a5,0x74727
    80005e98:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e9c:	14f71b63          	bne	a4,a5,80005ff2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ea0:	100017b7          	lui	a5,0x10001
    80005ea4:	43dc                	lw	a5,4(a5)
    80005ea6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ea8:	4709                	li	a4,2
    80005eaa:	14e79463          	bne	a5,a4,80005ff2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	479c                	lw	a5,8(a5)
    80005eb4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005eb6:	12e79e63          	bne	a5,a4,80005ff2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eba:	100017b7          	lui	a5,0x10001
    80005ebe:	47d8                	lw	a4,12(a5)
    80005ec0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ec2:	554d47b7          	lui	a5,0x554d4
    80005ec6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eca:	12f71463          	bne	a4,a5,80005ff2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed6:	4705                	li	a4,1
    80005ed8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eda:	470d                	li	a4,3
    80005edc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ede:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ee0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005ee4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fc47df>
    80005ee8:	8f75                	and	a4,a4,a3
    80005eea:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eec:	472d                	li	a4,11
    80005eee:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ef0:	5bbc                	lw	a5,112(a5)
    80005ef2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ef6:	8ba1                	andi	a5,a5,8
    80005ef8:	10078563          	beqz	a5,80006002 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f04:	43fc                	lw	a5,68(a5)
    80005f06:	2781                	sext.w	a5,a5
    80005f08:	10079563          	bnez	a5,80006012 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f0c:	100017b7          	lui	a5,0x10001
    80005f10:	5bdc                	lw	a5,52(a5)
    80005f12:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f14:	10078763          	beqz	a5,80006022 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f18:	471d                	li	a4,7
    80005f1a:	10f77c63          	bgeu	a4,a5,80006032 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f1e:	ffffb097          	auipc	ra,0xffffb
    80005f22:	bc8080e7          	jalr	-1080(ra) # 80000ae6 <kalloc>
    80005f26:	00034497          	auipc	s1,0x34
    80005f2a:	f1a48493          	addi	s1,s1,-230 # 80039e40 <disk>
    80005f2e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f30:	ffffb097          	auipc	ra,0xffffb
    80005f34:	bb6080e7          	jalr	-1098(ra) # 80000ae6 <kalloc>
    80005f38:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f3a:	ffffb097          	auipc	ra,0xffffb
    80005f3e:	bac080e7          	jalr	-1108(ra) # 80000ae6 <kalloc>
    80005f42:	87aa                	mv	a5,a0
    80005f44:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f46:	6088                	ld	a0,0(s1)
    80005f48:	cd6d                	beqz	a0,80006042 <virtio_disk_init+0x1da>
    80005f4a:	00034717          	auipc	a4,0x34
    80005f4e:	efe73703          	ld	a4,-258(a4) # 80039e48 <disk+0x8>
    80005f52:	cb65                	beqz	a4,80006042 <virtio_disk_init+0x1da>
    80005f54:	c7fd                	beqz	a5,80006042 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f56:	6605                	lui	a2,0x1
    80005f58:	4581                	li	a1,0
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	d78080e7          	jalr	-648(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f62:	00034497          	auipc	s1,0x34
    80005f66:	ede48493          	addi	s1,s1,-290 # 80039e40 <disk>
    80005f6a:	6605                	lui	a2,0x1
    80005f6c:	4581                	li	a1,0
    80005f6e:	6488                	ld	a0,8(s1)
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	d62080e7          	jalr	-670(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f78:	6605                	lui	a2,0x1
    80005f7a:	4581                	li	a1,0
    80005f7c:	6888                	ld	a0,16(s1)
    80005f7e:	ffffb097          	auipc	ra,0xffffb
    80005f82:	d54080e7          	jalr	-684(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f86:	100017b7          	lui	a5,0x10001
    80005f8a:	4721                	li	a4,8
    80005f8c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f8e:	4098                	lw	a4,0(s1)
    80005f90:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f94:	40d8                	lw	a4,4(s1)
    80005f96:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f9a:	6498                	ld	a4,8(s1)
    80005f9c:	0007069b          	sext.w	a3,a4
    80005fa0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fa4:	9701                	srai	a4,a4,0x20
    80005fa6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005faa:	6898                	ld	a4,16(s1)
    80005fac:	0007069b          	sext.w	a3,a4
    80005fb0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fb4:	9701                	srai	a4,a4,0x20
    80005fb6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fba:	4705                	li	a4,1
    80005fbc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fbe:	00e48c23          	sb	a4,24(s1)
    80005fc2:	00e48ca3          	sb	a4,25(s1)
    80005fc6:	00e48d23          	sb	a4,26(s1)
    80005fca:	00e48da3          	sb	a4,27(s1)
    80005fce:	00e48e23          	sb	a4,28(s1)
    80005fd2:	00e48ea3          	sb	a4,29(s1)
    80005fd6:	00e48f23          	sb	a4,30(s1)
    80005fda:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fde:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe2:	0727a823          	sw	s2,112(a5)
}
    80005fe6:	60e2                	ld	ra,24(sp)
    80005fe8:	6442                	ld	s0,16(sp)
    80005fea:	64a2                	ld	s1,8(sp)
    80005fec:	6902                	ld	s2,0(sp)
    80005fee:	6105                	addi	sp,sp,32
    80005ff0:	8082                	ret
    panic("could not find virtio disk");
    80005ff2:	00002517          	auipc	a0,0x2
    80005ff6:	79e50513          	addi	a0,a0,1950 # 80008790 <syscalls+0x338>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006002:	00002517          	auipc	a0,0x2
    80006006:	7ae50513          	addi	a0,a0,1966 # 800087b0 <syscalls+0x358>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006012:	00002517          	auipc	a0,0x2
    80006016:	7be50513          	addi	a0,a0,1982 # 800087d0 <syscalls+0x378>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006022:	00002517          	auipc	a0,0x2
    80006026:	7ce50513          	addi	a0,a0,1998 # 800087f0 <syscalls+0x398>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	516080e7          	jalr	1302(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006032:	00002517          	auipc	a0,0x2
    80006036:	7de50513          	addi	a0,a0,2014 # 80008810 <syscalls+0x3b8>
    8000603a:	ffffa097          	auipc	ra,0xffffa
    8000603e:	506080e7          	jalr	1286(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006042:	00002517          	auipc	a0,0x2
    80006046:	7ee50513          	addi	a0,a0,2030 # 80008830 <syscalls+0x3d8>
    8000604a:	ffffa097          	auipc	ra,0xffffa
    8000604e:	4f6080e7          	jalr	1270(ra) # 80000540 <panic>

0000000080006052 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006052:	7119                	addi	sp,sp,-128
    80006054:	fc86                	sd	ra,120(sp)
    80006056:	f8a2                	sd	s0,112(sp)
    80006058:	f4a6                	sd	s1,104(sp)
    8000605a:	f0ca                	sd	s2,96(sp)
    8000605c:	ecce                	sd	s3,88(sp)
    8000605e:	e8d2                	sd	s4,80(sp)
    80006060:	e4d6                	sd	s5,72(sp)
    80006062:	e0da                	sd	s6,64(sp)
    80006064:	fc5e                	sd	s7,56(sp)
    80006066:	f862                	sd	s8,48(sp)
    80006068:	f466                	sd	s9,40(sp)
    8000606a:	f06a                	sd	s10,32(sp)
    8000606c:	ec6e                	sd	s11,24(sp)
    8000606e:	0100                	addi	s0,sp,128
    80006070:	8aaa                	mv	s5,a0
    80006072:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006074:	00c52d03          	lw	s10,12(a0)
    80006078:	001d1d1b          	slliw	s10,s10,0x1
    8000607c:	1d02                	slli	s10,s10,0x20
    8000607e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006082:	00034517          	auipc	a0,0x34
    80006086:	ee650513          	addi	a0,a0,-282 # 80039f68 <disk+0x128>
    8000608a:	ffffb097          	auipc	ra,0xffffb
    8000608e:	b4c080e7          	jalr	-1204(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006092:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006094:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006096:	00034b97          	auipc	s7,0x34
    8000609a:	daab8b93          	addi	s7,s7,-598 # 80039e40 <disk>
  for(int i = 0; i < 3; i++){
    8000609e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060a0:	00034c97          	auipc	s9,0x34
    800060a4:	ec8c8c93          	addi	s9,s9,-312 # 80039f68 <disk+0x128>
    800060a8:	a08d                	j	8000610a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800060aa:	00fb8733          	add	a4,s7,a5
    800060ae:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060b2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060b4:	0207c563          	bltz	a5,800060de <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060b8:	2905                	addiw	s2,s2,1
    800060ba:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800060bc:	05690c63          	beq	s2,s6,80006114 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060c0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060c2:	00034717          	auipc	a4,0x34
    800060c6:	d7e70713          	addi	a4,a4,-642 # 80039e40 <disk>
    800060ca:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060cc:	01874683          	lbu	a3,24(a4)
    800060d0:	fee9                	bnez	a3,800060aa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060d2:	2785                	addiw	a5,a5,1
    800060d4:	0705                	addi	a4,a4,1
    800060d6:	fe979be3          	bne	a5,s1,800060cc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060da:	57fd                	li	a5,-1
    800060dc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060de:	01205d63          	blez	s2,800060f8 <virtio_disk_rw+0xa6>
    800060e2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060e4:	000a2503          	lw	a0,0(s4)
    800060e8:	00000097          	auipc	ra,0x0
    800060ec:	cfe080e7          	jalr	-770(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    800060f0:	2d85                	addiw	s11,s11,1
    800060f2:	0a11                	addi	s4,s4,4
    800060f4:	ff2d98e3          	bne	s11,s2,800060e4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f8:	85e6                	mv	a1,s9
    800060fa:	00034517          	auipc	a0,0x34
    800060fe:	d5e50513          	addi	a0,a0,-674 # 80039e58 <disk+0x18>
    80006102:	ffffc097          	auipc	ra,0xffffc
    80006106:	f52080e7          	jalr	-174(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    8000610a:	f8040a13          	addi	s4,s0,-128
{
    8000610e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006110:	894e                	mv	s2,s3
    80006112:	b77d                	j	800060c0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006114:	f8042503          	lw	a0,-128(s0)
    80006118:	00a50713          	addi	a4,a0,10
    8000611c:	0712                	slli	a4,a4,0x4

  if(write)
    8000611e:	00034797          	auipc	a5,0x34
    80006122:	d2278793          	addi	a5,a5,-734 # 80039e40 <disk>
    80006126:	00e786b3          	add	a3,a5,a4
    8000612a:	01803633          	snez	a2,s8
    8000612e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006130:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006134:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006138:	f6070613          	addi	a2,a4,-160
    8000613c:	6394                	ld	a3,0(a5)
    8000613e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006140:	00870593          	addi	a1,a4,8
    80006144:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006146:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006148:	0007b803          	ld	a6,0(a5)
    8000614c:	9642                	add	a2,a2,a6
    8000614e:	46c1                	li	a3,16
    80006150:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006152:	4585                	li	a1,1
    80006154:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006158:	f8442683          	lw	a3,-124(s0)
    8000615c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006160:	0692                	slli	a3,a3,0x4
    80006162:	9836                	add	a6,a6,a3
    80006164:	058a8613          	addi	a2,s5,88
    80006168:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000616c:	0007b803          	ld	a6,0(a5)
    80006170:	96c2                	add	a3,a3,a6
    80006172:	40000613          	li	a2,1024
    80006176:	c690                	sw	a2,8(a3)
  if(write)
    80006178:	001c3613          	seqz	a2,s8
    8000617c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006180:	00166613          	ori	a2,a2,1
    80006184:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006188:	f8842603          	lw	a2,-120(s0)
    8000618c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006190:	00250693          	addi	a3,a0,2
    80006194:	0692                	slli	a3,a3,0x4
    80006196:	96be                	add	a3,a3,a5
    80006198:	58fd                	li	a7,-1
    8000619a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000619e:	0612                	slli	a2,a2,0x4
    800061a0:	9832                	add	a6,a6,a2
    800061a2:	f9070713          	addi	a4,a4,-112
    800061a6:	973e                	add	a4,a4,a5
    800061a8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800061ac:	6398                	ld	a4,0(a5)
    800061ae:	9732                	add	a4,a4,a2
    800061b0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061b2:	4609                	li	a2,2
    800061b4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800061b8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061bc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800061c0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061c4:	6794                	ld	a3,8(a5)
    800061c6:	0026d703          	lhu	a4,2(a3)
    800061ca:	8b1d                	andi	a4,a4,7
    800061cc:	0706                	slli	a4,a4,0x1
    800061ce:	96ba                	add	a3,a3,a4
    800061d0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061d4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061d8:	6798                	ld	a4,8(a5)
    800061da:	00275783          	lhu	a5,2(a4)
    800061de:	2785                	addiw	a5,a5,1
    800061e0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061e4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061e8:	100017b7          	lui	a5,0x10001
    800061ec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061f0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800061f4:	00034917          	auipc	s2,0x34
    800061f8:	d7490913          	addi	s2,s2,-652 # 80039f68 <disk+0x128>
  while(b->disk == 1) {
    800061fc:	4485                	li	s1,1
    800061fe:	00b79c63          	bne	a5,a1,80006216 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006202:	85ca                	mv	a1,s2
    80006204:	8556                	mv	a0,s5
    80006206:	ffffc097          	auipc	ra,0xffffc
    8000620a:	e4e080e7          	jalr	-434(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    8000620e:	004aa783          	lw	a5,4(s5)
    80006212:	fe9788e3          	beq	a5,s1,80006202 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006216:	f8042903          	lw	s2,-128(s0)
    8000621a:	00290713          	addi	a4,s2,2
    8000621e:	0712                	slli	a4,a4,0x4
    80006220:	00034797          	auipc	a5,0x34
    80006224:	c2078793          	addi	a5,a5,-992 # 80039e40 <disk>
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000622e:	00034997          	auipc	s3,0x34
    80006232:	c1298993          	addi	s3,s3,-1006 # 80039e40 <disk>
    80006236:	00491713          	slli	a4,s2,0x4
    8000623a:	0009b783          	ld	a5,0(s3)
    8000623e:	97ba                	add	a5,a5,a4
    80006240:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006244:	854a                	mv	a0,s2
    80006246:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000624a:	00000097          	auipc	ra,0x0
    8000624e:	b9c080e7          	jalr	-1124(ra) # 80005de6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006252:	8885                	andi	s1,s1,1
    80006254:	f0ed                	bnez	s1,80006236 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006256:	00034517          	auipc	a0,0x34
    8000625a:	d1250513          	addi	a0,a0,-750 # 80039f68 <disk+0x128>
    8000625e:	ffffb097          	auipc	ra,0xffffb
    80006262:	a2c080e7          	jalr	-1492(ra) # 80000c8a <release>
}
    80006266:	70e6                	ld	ra,120(sp)
    80006268:	7446                	ld	s0,112(sp)
    8000626a:	74a6                	ld	s1,104(sp)
    8000626c:	7906                	ld	s2,96(sp)
    8000626e:	69e6                	ld	s3,88(sp)
    80006270:	6a46                	ld	s4,80(sp)
    80006272:	6aa6                	ld	s5,72(sp)
    80006274:	6b06                	ld	s6,64(sp)
    80006276:	7be2                	ld	s7,56(sp)
    80006278:	7c42                	ld	s8,48(sp)
    8000627a:	7ca2                	ld	s9,40(sp)
    8000627c:	7d02                	ld	s10,32(sp)
    8000627e:	6de2                	ld	s11,24(sp)
    80006280:	6109                	addi	sp,sp,128
    80006282:	8082                	ret

0000000080006284 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006284:	1101                	addi	sp,sp,-32
    80006286:	ec06                	sd	ra,24(sp)
    80006288:	e822                	sd	s0,16(sp)
    8000628a:	e426                	sd	s1,8(sp)
    8000628c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000628e:	00034497          	auipc	s1,0x34
    80006292:	bb248493          	addi	s1,s1,-1102 # 80039e40 <disk>
    80006296:	00034517          	auipc	a0,0x34
    8000629a:	cd250513          	addi	a0,a0,-814 # 80039f68 <disk+0x128>
    8000629e:	ffffb097          	auipc	ra,0xffffb
    800062a2:	938080e7          	jalr	-1736(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062a6:	10001737          	lui	a4,0x10001
    800062aa:	533c                	lw	a5,96(a4)
    800062ac:	8b8d                	andi	a5,a5,3
    800062ae:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062b0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062b4:	689c                	ld	a5,16(s1)
    800062b6:	0204d703          	lhu	a4,32(s1)
    800062ba:	0027d783          	lhu	a5,2(a5)
    800062be:	04f70863          	beq	a4,a5,8000630e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062c2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062c6:	6898                	ld	a4,16(s1)
    800062c8:	0204d783          	lhu	a5,32(s1)
    800062cc:	8b9d                	andi	a5,a5,7
    800062ce:	078e                	slli	a5,a5,0x3
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062d4:	00278713          	addi	a4,a5,2
    800062d8:	0712                	slli	a4,a4,0x4
    800062da:	9726                	add	a4,a4,s1
    800062dc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062e0:	e721                	bnez	a4,80006328 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062e2:	0789                	addi	a5,a5,2
    800062e4:	0792                	slli	a5,a5,0x4
    800062e6:	97a6                	add	a5,a5,s1
    800062e8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062ea:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062ee:	ffffc097          	auipc	ra,0xffffc
    800062f2:	dca080e7          	jalr	-566(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    800062f6:	0204d783          	lhu	a5,32(s1)
    800062fa:	2785                	addiw	a5,a5,1
    800062fc:	17c2                	slli	a5,a5,0x30
    800062fe:	93c1                	srli	a5,a5,0x30
    80006300:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006304:	6898                	ld	a4,16(s1)
    80006306:	00275703          	lhu	a4,2(a4)
    8000630a:	faf71ce3          	bne	a4,a5,800062c2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000630e:	00034517          	auipc	a0,0x34
    80006312:	c5a50513          	addi	a0,a0,-934 # 80039f68 <disk+0x128>
    80006316:	ffffb097          	auipc	ra,0xffffb
    8000631a:	974080e7          	jalr	-1676(ra) # 80000c8a <release>
}
    8000631e:	60e2                	ld	ra,24(sp)
    80006320:	6442                	ld	s0,16(sp)
    80006322:	64a2                	ld	s1,8(sp)
    80006324:	6105                	addi	sp,sp,32
    80006326:	8082                	ret
      panic("virtio_disk_intr status");
    80006328:	00002517          	auipc	a0,0x2
    8000632c:	52050513          	addi	a0,a0,1312 # 80008848 <syscalls+0x3f0>
    80006330:	ffffa097          	auipc	ra,0xffffa
    80006334:	210080e7          	jalr	528(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
