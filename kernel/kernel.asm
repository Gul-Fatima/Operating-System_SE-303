
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	00008117          	auipc	sp,0x8
    80000004:	8d010113          	addi	sp,sp,-1840 # 800078d0 <stack0>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	stimecmp,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdd627>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dbc78793          	addi	a5,a5,-580 # 80000e3c <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7119                	addi	sp,sp,-128
    800000d2:	fc86                	sd	ra,120(sp)
    800000d4:	f8a2                	sd	s0,112(sp)
    800000d6:	f4a6                	sd	s1,104(sp)
    800000d8:	0100                	addi	s0,sp,128
  char buf[32];
  int i = 0;

  while(i < n){
    800000da:	06c05a63          	blez	a2,8000014e <consolewrite+0x7e>
    800000de:	f0ca                	sd	s2,96(sp)
    800000e0:	ecce                	sd	s3,88(sp)
    800000e2:	e8d2                	sd	s4,80(sp)
    800000e4:	e4d6                	sd	s5,72(sp)
    800000e6:	e0da                	sd	s6,64(sp)
    800000e8:	fc5e                	sd	s7,56(sp)
    800000ea:	f862                	sd	s8,48(sp)
    800000ec:	f466                	sd	s9,40(sp)
    800000ee:	8aaa                	mv	s5,a0
    800000f0:	8b2e                	mv	s6,a1
    800000f2:	8a32                	mv	s4,a2
  int i = 0;
    800000f4:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f6:	02000c13          	li	s8,32
    800000fa:	02000c93          	li	s9,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fe:	5bfd                	li	s7,-1
    80000100:	a035                	j	8000012c <consolewrite+0x5c>
    if(nn > n - i)
    80000102:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000106:	86ce                	mv	a3,s3
    80000108:	01648633          	add	a2,s1,s6
    8000010c:	85d6                	mv	a1,s5
    8000010e:	f8040513          	addi	a0,s0,-128
    80000112:	222020ef          	jal	80002334 <either_copyin>
    80000116:	03750e63          	beq	a0,s7,80000152 <consolewrite+0x82>
      break;
    uartwrite(buf, nn);
    8000011a:	85ce                	mv	a1,s3
    8000011c:	f8040513          	addi	a0,s0,-128
    80000120:	778000ef          	jal	80000898 <uartwrite>
    i += nn;
    80000124:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000128:	0144da63          	bge	s1,s4,8000013c <consolewrite+0x6c>
    if(nn > n - i)
    8000012c:	409a093b          	subw	s2,s4,s1
    80000130:	0009079b          	sext.w	a5,s2
    80000134:	fcfc57e3          	bge	s8,a5,80000102 <consolewrite+0x32>
    80000138:	8966                	mv	s2,s9
    8000013a:	b7e1                	j	80000102 <consolewrite+0x32>
    8000013c:	7906                	ld	s2,96(sp)
    8000013e:	69e6                	ld	s3,88(sp)
    80000140:	6a46                	ld	s4,80(sp)
    80000142:	6aa6                	ld	s5,72(sp)
    80000144:	6b06                	ld	s6,64(sp)
    80000146:	7be2                	ld	s7,56(sp)
    80000148:	7c42                	ld	s8,48(sp)
    8000014a:	7ca2                	ld	s9,40(sp)
    8000014c:	a819                	j	80000162 <consolewrite+0x92>
  int i = 0;
    8000014e:	4481                	li	s1,0
    80000150:	a809                	j	80000162 <consolewrite+0x92>
    80000152:	7906                	ld	s2,96(sp)
    80000154:	69e6                	ld	s3,88(sp)
    80000156:	6a46                	ld	s4,80(sp)
    80000158:	6aa6                	ld	s5,72(sp)
    8000015a:	6b06                	ld	s6,64(sp)
    8000015c:	7be2                	ld	s7,56(sp)
    8000015e:	7c42                	ld	s8,48(sp)
    80000160:	7ca2                	ld	s9,40(sp)
  }

  return i;
}
    80000162:	8526                	mv	a0,s1
    80000164:	70e6                	ld	ra,120(sp)
    80000166:	7446                	ld	s0,112(sp)
    80000168:	74a6                	ld	s1,104(sp)
    8000016a:	6109                	addi	sp,sp,128
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	0000f517          	auipc	a0,0xf
    80000190:	74450513          	addi	a0,a0,1860 # 8000f8d0 <cons>
    80000194:	23b000ef          	jal	80000bce <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	0000f497          	auipc	s1,0xf
    8000019c:	73848493          	addi	s1,s1,1848 # 8000f8d0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	0000f917          	auipc	s2,0xf
    800001a4:	7c890913          	addi	s2,s2,1992 # 8000f968 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	716010ef          	jal	800018ce <myproc>
    800001bc:	00a020ef          	jal	800021c6 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	5c1010ef          	jal	80001f86 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	0000f717          	auipc	a4,0xf
    800001dc:	6f870713          	addi	a4,a4,1784 # 8000f8d0 <cons>
    800001e0:	0017869b          	addiw	a3,a5,1
    800001e4:	08d72c23          	sw	a3,152(a4)
    800001e8:	07f7f693          	andi	a3,a5,127
    800001ec:	9736                	add	a4,a4,a3
    800001ee:	01874703          	lbu	a4,24(a4)
    800001f2:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001f6:	4691                	li	a3,4
    800001f8:	04db8663          	beq	s7,a3,80000244 <consoleread+0xd6>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    800001fc:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000200:	4685                	li	a3,1
    80000202:	faf40613          	addi	a2,s0,-81
    80000206:	85d2                	mv	a1,s4
    80000208:	8556                	mv	a0,s5
    8000020a:	0e0020ef          	jal	800022ea <either_copyout>
    8000020e:	57fd                	li	a5,-1
    80000210:	04f50863          	beq	a0,a5,80000260 <consoleread+0xf2>
      break;

    dst++;
    80000214:	0a05                	addi	s4,s4,1
    --n;
    80000216:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000218:	47a9                	li	a5,10
    8000021a:	04fb8d63          	beq	s7,a5,80000274 <consoleread+0x106>
    8000021e:	6be2                	ld	s7,24(sp)
    80000220:	b761                	j	800001a8 <consoleread+0x3a>
        release(&cons.lock);
    80000222:	0000f517          	auipc	a0,0xf
    80000226:	6ae50513          	addi	a0,a0,1710 # 8000f8d0 <cons>
    8000022a:	23d000ef          	jal	80000c66 <release>
        return -1;
    8000022e:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000230:	60e6                	ld	ra,88(sp)
    80000232:	6446                	ld	s0,80(sp)
    80000234:	64a6                	ld	s1,72(sp)
    80000236:	6906                	ld	s2,64(sp)
    80000238:	79e2                	ld	s3,56(sp)
    8000023a:	7a42                	ld	s4,48(sp)
    8000023c:	7aa2                	ld	s5,40(sp)
    8000023e:	7b02                	ld	s6,32(sp)
    80000240:	6125                	addi	sp,sp,96
    80000242:	8082                	ret
      if(n < target){
    80000244:	0009871b          	sext.w	a4,s3
    80000248:	01677a63          	bgeu	a4,s6,8000025c <consoleread+0xee>
        cons.r--;
    8000024c:	0000f717          	auipc	a4,0xf
    80000250:	70f72e23          	sw	a5,1820(a4) # 8000f968 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	0000f517          	auipc	a0,0xf
    80000266:	66e50513          	addi	a0,a0,1646 # 8000f8d0 <cons>
    8000026a:	1fd000ef          	jal	80000c66 <release>
  return target - n;
    8000026e:	413b053b          	subw	a0,s6,s3
    80000272:	bf7d                	j	80000230 <consoleread+0xc2>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	b7f5                	j	80000262 <consoleread+0xf4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50863          	beq	a0,a5,80000294 <consputc+0x1c>
    uartputc_sync(c);
    80000288:	6a4000ef          	jal	8000092c <uartputc_sync>
}
    8000028c:	60a2                	ld	ra,8(sp)
    8000028e:	6402                	ld	s0,0(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000294:	4521                	li	a0,8
    80000296:	696000ef          	jal	8000092c <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	68e000ef          	jal	8000092c <uartputc_sync>
    800002a2:	4521                	li	a0,8
    800002a4:	688000ef          	jal	8000092c <uartputc_sync>
    800002a8:	b7d5                	j	8000028c <consputc+0x14>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	1000                	addi	s0,sp,32
    800002b4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b6:	0000f517          	auipc	a0,0xf
    800002ba:	61a50513          	addi	a0,a0,1562 # 8000f8d0 <cons>
    800002be:	111000ef          	jal	80000bce <acquire>

  switch(c){
    800002c2:	47d5                	li	a5,21
    800002c4:	08f48f63          	beq	s1,a5,80000362 <consoleintr+0xb8>
    800002c8:	0297c563          	blt	a5,s1,800002f2 <consoleintr+0x48>
    800002cc:	47a1                	li	a5,8
    800002ce:	0ef48463          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    800002d2:	47c1                	li	a5,16
    800002d4:	10f49563          	bne	s1,a5,800003de <consoleintr+0x134>
  case C('P'):  // Print process list.
    procdump();
    800002d8:	0a6020ef          	jal	8000237e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	0000f517          	auipc	a0,0xf
    800002e0:	5f450513          	addi	a0,a0,1524 # 8000f8d0 <cons>
    800002e4:	183000ef          	jal	80000c66 <release>
}
    800002e8:	60e2                	ld	ra,24(sp)
    800002ea:	6442                	ld	s0,16(sp)
    800002ec:	64a2                	ld	s1,8(sp)
    800002ee:	6105                	addi	sp,sp,32
    800002f0:	8082                	ret
  switch(c){
    800002f2:	07f00793          	li	a5,127
    800002f6:	0cf48063          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fa:	0000f717          	auipc	a4,0xf
    800002fe:	5d670713          	addi	a4,a4,1494 # 8000f8d0 <cons>
    80000302:	0a072783          	lw	a5,160(a4)
    80000306:	09872703          	lw	a4,152(a4)
    8000030a:	9f99                	subw	a5,a5,a4
    8000030c:	07f00713          	li	a4,127
    80000310:	fcf766e3          	bltu	a4,a5,800002dc <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000314:	47b5                	li	a5,13
    80000316:	0cf48763          	beq	s1,a5,800003e4 <consoleintr+0x13a>
      consputc(c);
    8000031a:	8526                	mv	a0,s1
    8000031c:	f5dff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000320:	0000f797          	auipc	a5,0xf
    80000324:	5b078793          	addi	a5,a5,1456 # 8000f8d0 <cons>
    80000328:	0a07a683          	lw	a3,160(a5)
    8000032c:	0016871b          	addiw	a4,a3,1
    80000330:	0007061b          	sext.w	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48563          	beq	s1,a5,8000040e <consoleintr+0x164>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48263          	beq	s1,a5,8000040e <consoleintr+0x164>
    8000034e:	0000f797          	auipc	a5,0xf
    80000352:	61a7a783          	lw	a5,1562(a5) # 8000f968 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	0000f717          	auipc	a4,0xf
    80000368:	56c70713          	addi	a4,a4,1388 # 8000f8d0 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	0000f497          	auipc	s1,0xf
    80000378:	55c48493          	addi	s1,s1,1372 # 8000f8d0 <cons>
    while(cons.e != cons.w &&
    8000037c:	4929                	li	s2,10
    8000037e:	02f70863          	beq	a4,a5,800003ae <consoleintr+0x104>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000382:	37fd                	addiw	a5,a5,-1
    80000384:	07f7f713          	andi	a4,a5,127
    80000388:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000038a:	01874703          	lbu	a4,24(a4)
    8000038e:	03270263          	beq	a4,s2,800003b2 <consoleintr+0x108>
      cons.e--;
    80000392:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000396:	10000513          	li	a0,256
    8000039a:	edfff0ef          	jal	80000278 <consputc>
    while(cons.e != cons.w &&
    8000039e:	0a04a783          	lw	a5,160(s1)
    800003a2:	09c4a703          	lw	a4,156(s1)
    800003a6:	fcf71ee3          	bne	a4,a5,80000382 <consoleintr+0xd8>
    800003aa:	6902                	ld	s2,0(sp)
    800003ac:	bf05                	j	800002dc <consoleintr+0x32>
    800003ae:	6902                	ld	s2,0(sp)
    800003b0:	b735                	j	800002dc <consoleintr+0x32>
    800003b2:	6902                	ld	s2,0(sp)
    800003b4:	b725                	j	800002dc <consoleintr+0x32>
    if(cons.e != cons.w){
    800003b6:	0000f717          	auipc	a4,0xf
    800003ba:	51a70713          	addi	a4,a4,1306 # 8000f8d0 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	0000f717          	auipc	a4,0xf
    800003d0:	5af72223          	sw	a5,1444(a4) # 8000f970 <cons+0xa0>
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	ea1ff0ef          	jal	80000278 <consputc>
    800003dc:	b701                	j	800002dc <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003de:	ee048fe3          	beqz	s1,800002dc <consoleintr+0x32>
    800003e2:	bf21                	j	800002fa <consoleintr+0x50>
      consputc(c);
    800003e4:	4529                	li	a0,10
    800003e6:	e93ff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003ea:	0000f797          	auipc	a5,0xf
    800003ee:	4e678793          	addi	a5,a5,1254 # 8000f8d0 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	0000f797          	auipc	a5,0xf
    80000412:	54c7af23          	sw	a2,1374(a5) # 8000f96c <cons+0x9c>
        wakeup(&cons.r);
    80000416:	0000f517          	auipc	a0,0xf
    8000041a:	55250513          	addi	a0,a0,1362 # 8000f968 <cons+0x98>
    8000041e:	3b5010ef          	jal	80001fd2 <wakeup>
    80000422:	bd6d                	j	800002dc <consoleintr+0x32>

0000000080000424 <consoleinit>:

void
consoleinit(void)
{
    80000424:	1141                	addi	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000042c:	00007597          	auipc	a1,0x7
    80000430:	bd458593          	addi	a1,a1,-1068 # 80007000 <etext>
    80000434:	0000f517          	auipc	a0,0xf
    80000438:	49c50513          	addi	a0,a0,1180 # 8000f8d0 <cons>
    8000043c:	712000ef          	jal	80000b4e <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00020797          	auipc	a5,0x20
    80000448:	bfc78793          	addi	a5,a5,-1028 # 80020040 <devsw>
    8000044c:	00000717          	auipc	a4,0x0
    80000450:	d2270713          	addi	a4,a4,-734 # 8000016e <consoleread>
    80000454:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000456:	00000717          	auipc	a4,0x0
    8000045a:	c7a70713          	addi	a4,a4,-902 # 800000d0 <consolewrite>
    8000045e:	ef98                	sd	a4,24(a5)
}
    80000460:	60a2                	ld	ra,8(sp)
    80000462:	6402                	ld	s0,0(sp)
    80000464:	0141                	addi	sp,sp,16
    80000466:	8082                	ret

0000000080000468 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    80000470:	c219                	beqz	a2,80000476 <printint+0xe>
    80000472:	08054063          	bltz	a0,800004f2 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    80000476:	4881                	li	a7,0
    80000478:	fc840693          	addi	a3,s0,-56

  i = 0;
    8000047c:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000047e:	00007617          	auipc	a2,0x7
    80000482:	2da60613          	addi	a2,a2,730 # 80007758 <digits>
    80000486:	883e                	mv	a6,a5
    80000488:	2785                	addiw	a5,a5,1
    8000048a:	02b57733          	remu	a4,a0,a1
    8000048e:	9732                	add	a4,a4,a2
    80000490:	00074703          	lbu	a4,0(a4)
    80000494:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000498:	872a                	mv	a4,a0
    8000049a:	02b55533          	divu	a0,a0,a1
    8000049e:	0685                	addi	a3,a3,1
    800004a0:	feb773e3          	bgeu	a4,a1,80000486 <printint+0x1e>

  if(sign)
    800004a4:	00088a63          	beqz	a7,800004b8 <printint+0x50>
    buf[i++] = '-';
    800004a8:	1781                	addi	a5,a5,-32
    800004aa:	97a2                	add	a5,a5,s0
    800004ac:	02d00713          	li	a4,45
    800004b0:	fee78423          	sb	a4,-24(a5)
    800004b4:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004b8:	02f05963          	blez	a5,800004ea <printint+0x82>
    800004bc:	f426                	sd	s1,40(sp)
    800004be:	f04a                	sd	s2,32(sp)
    800004c0:	fc840713          	addi	a4,s0,-56
    800004c4:	00f704b3          	add	s1,a4,a5
    800004c8:	fff70913          	addi	s2,a4,-1
    800004cc:	993e                	add	s2,s2,a5
    800004ce:	37fd                	addiw	a5,a5,-1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004d8:	fff4c503          	lbu	a0,-1(s1)
    800004dc:	d9dff0ef          	jal	80000278 <consputc>
  while(--i >= 0)
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	ff249be3          	bne	s1,s2,800004d8 <printint+0x70>
    800004e6:	74a2                	ld	s1,40(sp)
    800004e8:	7902                	ld	s2,32(sp)
}
    800004ea:	70e2                	ld	ra,56(sp)
    800004ec:	7442                	ld	s0,48(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4885                	li	a7,1
    x = -xx;
    800004f8:	b741                	j	80000478 <printint+0x10>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	00007797          	auipc	a5,0x7
    8000051c:	38c7a783          	lw	a5,908(a5) # 800078a4 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050763          	beqz	a0,800007bc <printf+0x2c2>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4981                	li	s3,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a01d                	j	80000584 <printf+0x8a>
    acquire(&pr.lock);
    80000560:	0000f517          	auipc	a0,0xf
    80000564:	41850513          	addi	a0,a0,1048 # 8000f978 <pr>
    80000568:	666000ef          	jal	80000bce <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0bff0ef          	jal	80000278 <consputc>
      continue;
    80000572:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	0014899b          	addiw	s3,s1,1
    80000578:	013a07b3          	add	a5,s4,s3
    8000057c:	0007c503          	lbu	a0,0(a5)
    80000580:	20050b63          	beqz	a0,80000796 <printf+0x29c>
    if(cx != '%'){
    80000584:	ff5515e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000588:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000058c:	009a07b3          	add	a5,s4,s1
    80000590:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20090b63          	beqz	s2,800007aa <printf+0x2b0>
    80000598:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000059c:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c789                	beqz	a5,800005a8 <printf+0xae>
    800005a0:	009a0733          	add	a4,s4,s1
    800005a4:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005a8:	03690963          	beq	s2,s6,800005da <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005ac:	05890363          	beq	s2,s8,800005f2 <printf+0xf8>
    } else if(c0 == 'u'){
    800005b0:	0d990663          	beq	s2,s9,8000067c <printf+0x182>
    } else if(c0 == 'x'){
    800005b4:	11a90d63          	beq	s2,s10,800006ce <printf+0x1d4>
    } else if(c0 == 'p'){
    800005b8:	15b90663          	beq	s2,s11,80000704 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005bc:	06300793          	li	a5,99
    800005c0:	18f90563          	beq	s2,a5,8000074a <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c4:	07300793          	li	a5,115
    800005c8:	18f90b63          	beq	s2,a5,8000075e <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005cc:	03591b63          	bne	s2,s5,80000602 <printf+0x108>
      consputc('%');
    800005d0:	02500513          	li	a0,37
    800005d4:	ca5ff0ef          	jal	80000278 <consputc>
    800005d8:	bf71                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005da:	f8843783          	ld	a5,-120(s0)
    800005de:	00878713          	addi	a4,a5,8
    800005e2:	f8e43423          	sd	a4,-120(s0)
    800005e6:	4605                	li	a2,1
    800005e8:	45a9                	li	a1,10
    800005ea:	4388                	lw	a0,0(a5)
    800005ec:	e7dff0ef          	jal	80000468 <printint>
    800005f0:	b751                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f2:	01678f63          	beq	a5,s6,80000610 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f6:	03878b63          	beq	a5,s8,8000062c <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    800005fa:	09978e63          	beq	a5,s9,80000696 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fe:	0fa78563          	beq	a5,s10,800006e8 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000602:	8556                	mv	a0,s5
    80000604:	c75ff0ef          	jal	80000278 <consputc>
      consputc(c0);
    80000608:	854a                	mv	a0,s2
    8000060a:	c6fff0ef          	jal	80000278 <consputc>
    8000060e:	b79d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000610:	f8843783          	ld	a5,-120(s0)
    80000614:	00878713          	addi	a4,a5,8
    80000618:	f8e43423          	sd	a4,-120(s0)
    8000061c:	4605                	li	a2,1
    8000061e:	45a9                	li	a1,10
    80000620:	6388                	ld	a0,0(a5)
    80000622:	e47ff0ef          	jal	80000468 <printint>
      i += 1;
    80000626:	0029849b          	addiw	s1,s3,2
    8000062a:	b7a9                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062c:	06400793          	li	a5,100
    80000630:	02f68863          	beq	a3,a5,80000660 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000634:	07500793          	li	a5,117
    80000638:	06f68d63          	beq	a3,a5,800006b2 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063c:	07800793          	li	a5,120
    80000640:	fcf691e3          	bne	a3,a5,80000602 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4601                	li	a2,0
    80000652:	45c1                	li	a1,16
    80000654:	6388                	ld	a0,0(a5)
    80000656:	e13ff0ef          	jal	80000468 <printint>
      i += 2;
    8000065a:	0039849b          	addiw	s1,s3,3
    8000065e:	bf19                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	df7ff0ef          	jal	80000468 <printint>
      i += 2;
    80000676:	0039849b          	addiw	s1,s3,3
    8000067a:	bded                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	0007e503          	lwu	a0,0(a5)
    80000690:	dd9ff0ef          	jal	80000468 <printint>
    80000694:	b5c5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4601                	li	a2,0
    800006a4:	45a9                	li	a1,10
    800006a6:	6388                	ld	a0,0(a5)
    800006a8:	dc1ff0ef          	jal	80000468 <printint>
      i += 1;
    800006ac:	0029849b          	addiw	s1,s3,2
    800006b0:	b5d1                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45a9                	li	a1,10
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	da5ff0ef          	jal	80000468 <printint>
      i += 2;
    800006c8:	0039849b          	addiw	s1,s3,3
    800006cc:	b565                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	4601                	li	a2,0
    800006dc:	45c1                	li	a1,16
    800006de:	0007e503          	lwu	a0,0(a5)
    800006e2:	d87ff0ef          	jal	80000468 <printint>
    800006e6:	b579                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	4601                	li	a2,0
    800006f6:	45c1                	li	a1,16
    800006f8:	6388                	ld	a0,0(a5)
    800006fa:	d6fff0ef          	jal	80000468 <printint>
      i += 1;
    800006fe:	0029849b          	addiw	s1,s3,2
    80000702:	bd8d                	j	80000574 <printf+0x7a>
    80000704:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000716:	03000513          	li	a0,48
    8000071a:	b5fff0ef          	jal	80000278 <consputc>
  consputc('x');
    8000071e:	07800513          	li	a0,120
    80000722:	b57ff0ef          	jal	80000278 <consputc>
    80000726:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000728:	00007b97          	auipc	s7,0x7
    8000072c:	030b8b93          	addi	s7,s7,48 # 80007758 <digits>
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	97de                	add	a5,a5,s7
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	b3fff0ef          	jal	80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073e:	0992                	slli	s3,s3,0x4
    80000740:	397d                	addiw	s2,s2,-1
    80000742:	fe0917e3          	bnez	s2,80000730 <printf+0x236>
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	b535                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000074a:	f8843783          	ld	a5,-120(s0)
    8000074e:	00878713          	addi	a4,a5,8
    80000752:	f8e43423          	sd	a4,-120(s0)
    80000756:	4388                	lw	a0,0(a5)
    80000758:	b21ff0ef          	jal	80000278 <consputc>
    8000075c:	bd21                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	0007b903          	ld	s2,0(a5)
    8000076e:	00090d63          	beqz	s2,80000788 <printf+0x28e>
      for(; *s; s++)
    80000772:	00094503          	lbu	a0,0(s2)
    80000776:	de050fe3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    8000077a:	affff0ef          	jal	80000278 <consputc>
      for(; *s; s++)
    8000077e:	0905                	addi	s2,s2,1
    80000780:	00094503          	lbu	a0,0(s2)
    80000784:	f97d                	bnez	a0,8000077a <printf+0x280>
    80000786:	b3fd                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000788:	00007917          	auipc	s2,0x7
    8000078c:	88090913          	addi	s2,s2,-1920 # 80007008 <etext+0x8>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	b7dd                	j	8000077a <printf+0x280>
    80000796:	74a6                	ld	s1,104(sp)
    80000798:	7906                	ld	s2,96(sp)
    8000079a:	69e6                	ld	s3,88(sp)
    8000079c:	6aa6                	ld	s5,72(sp)
    8000079e:	6b06                	ld	s6,64(sp)
    800007a0:	7c42                	ld	s8,48(sp)
    800007a2:	7ca2                	ld	s9,40(sp)
    800007a4:	7d02                	ld	s10,32(sp)
    800007a6:	6de2                	ld	s11,24(sp)
    800007a8:	a811                	j	800007bc <printf+0x2c2>
    800007aa:	74a6                	ld	s1,104(sp)
    800007ac:	7906                	ld	s2,96(sp)
    800007ae:	69e6                	ld	s3,88(sp)
    800007b0:	6aa6                	ld	s5,72(sp)
    800007b2:	6b06                	ld	s6,64(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007bc:	00007797          	auipc	a5,0x7
    800007c0:	0e87a783          	lw	a5,232(a5) # 800078a4 <panicking>
    800007c4:	c799                	beqz	a5,800007d2 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007c6:	4501                	li	a0,0
    800007c8:	70e6                	ld	ra,120(sp)
    800007ca:	7446                	ld	s0,112(sp)
    800007cc:	6a46                	ld	s4,80(sp)
    800007ce:	6129                	addi	sp,sp,192
    800007d0:	8082                	ret
    release(&pr.lock);
    800007d2:	0000f517          	auipc	a0,0xf
    800007d6:	1a650513          	addi	a0,a0,422 # 8000f978 <pr>
    800007da:	48c000ef          	jal	80000c66 <release>
  return 0;
    800007de:	b7e5                	j	800007c6 <printf+0x2cc>

00000000800007e0 <panic>:

void
panic(char *s)
{
    800007e0:	1101                	addi	sp,sp,-32
    800007e2:	ec06                	sd	ra,24(sp)
    800007e4:	e822                	sd	s0,16(sp)
    800007e6:	e426                	sd	s1,8(sp)
    800007e8:	e04a                	sd	s2,0(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  panicking = 1;
    800007ee:	4905                	li	s2,1
    800007f0:	00007797          	auipc	a5,0x7
    800007f4:	0b27aa23          	sw	s2,180(a5) # 800078a4 <panicking>
  printf("panic: ");
    800007f8:	00007517          	auipc	a0,0x7
    800007fc:	82050513          	addi	a0,a0,-2016 # 80007018 <etext+0x18>
    80000800:	cfbff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000804:	85a6                	mv	a1,s1
    80000806:	00007517          	auipc	a0,0x7
    8000080a:	81a50513          	addi	a0,a0,-2022 # 80007020 <etext+0x20>
    8000080e:	cedff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	00007797          	auipc	a5,0x7
    80000816:	0927a723          	sw	s2,142(a5) # 800078a0 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3a>

000000008000081c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000824:	00007597          	auipc	a1,0x7
    80000828:	80458593          	addi	a1,a1,-2044 # 80007028 <etext+0x28>
    8000082c:	0000f517          	auipc	a0,0xf
    80000830:	14c50513          	addi	a0,a0,332 # 8000f978 <pr>
    80000834:	31a000ef          	jal	80000b4e <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000840:	1141                	addi	sp,sp,-16
    80000842:	e406                	sd	ra,8(sp)
    80000844:	e022                	sd	s0,0(sp)
    80000846:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000848:	100007b7          	lui	a5,0x10000
    8000084c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000850:	10000737          	lui	a4,0x10000
    80000854:	f8000693          	li	a3,-128
    80000858:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085c:	468d                	li	a3,3
    8000085e:	10000637          	lui	a2,0x10000
    80000862:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000866:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000086a:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086e:	10000737          	lui	a4,0x10000
    80000872:	461d                	li	a2,7
    80000874:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000878:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    8000087c:	00006597          	auipc	a1,0x6
    80000880:	7b458593          	addi	a1,a1,1972 # 80007030 <etext+0x30>
    80000884:	0000f517          	auipc	a0,0xf
    80000888:	10c50513          	addi	a0,a0,268 # 8000f990 <tx_lock>
    8000088c:	2c2000ef          	jal	80000b4e <initlock>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000898:	715d                	addi	sp,sp,-80
    8000089a:	e486                	sd	ra,72(sp)
    8000089c:	e0a2                	sd	s0,64(sp)
    8000089e:	fc26                	sd	s1,56(sp)
    800008a0:	ec56                	sd	s5,24(sp)
    800008a2:	0880                	addi	s0,sp,80
    800008a4:	8aaa                	mv	s5,a0
    800008a6:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a8:	0000f517          	auipc	a0,0xf
    800008ac:	0e850513          	addi	a0,a0,232 # 8000f990 <tx_lock>
    800008b0:	31e000ef          	jal	80000bce <acquire>

  int i = 0;
  while(i < n){ 
    800008b4:	06905063          	blez	s1,80000914 <uartwrite+0x7c>
    800008b8:	f84a                	sd	s2,48(sp)
    800008ba:	f44e                	sd	s3,40(sp)
    800008bc:	f052                	sd	s4,32(sp)
    800008be:	e85a                	sd	s6,16(sp)
    800008c0:	e45e                	sd	s7,8(sp)
    800008c2:	8a56                	mv	s4,s5
    800008c4:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c6:	00007497          	auipc	s1,0x7
    800008ca:	fe648493          	addi	s1,s1,-26 # 800078ac <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	0000f997          	auipc	s3,0xf
    800008d2:	0c298993          	addi	s3,s3,194 # 8000f990 <tx_lock>
    800008d6:	00007917          	auipc	s2,0x7
    800008da:	fd290913          	addi	s2,s2,-46 # 800078a8 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    800008de:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008e2:	4b05                	li	s6,1
    800008e4:	a005                	j	80000904 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e6:	85ce                	mv	a1,s3
    800008e8:	854a                	mv	a0,s2
    800008ea:	69c010ef          	jal	80001f86 <sleep>
    while(tx_busy != 0){
    800008ee:	409c                	lw	a5,0(s1)
    800008f0:	fbfd                	bnez	a5,800008e6 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008f2:	000a4783          	lbu	a5,0(s4)
    800008f6:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008fa:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fe:	0a05                	addi	s4,s4,1
    80000900:	015a0563          	beq	s4,s5,8000090a <uartwrite+0x72>
    while(tx_busy != 0){
    80000904:	409c                	lw	a5,0(s1)
    80000906:	f3e5                	bnez	a5,800008e6 <uartwrite+0x4e>
    80000908:	b7ed                	j	800008f2 <uartwrite+0x5a>
    8000090a:	7942                	ld	s2,48(sp)
    8000090c:	79a2                	ld	s3,40(sp)
    8000090e:	7a02                	ld	s4,32(sp)
    80000910:	6b42                	ld	s6,16(sp)
    80000912:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000914:	0000f517          	auipc	a0,0xf
    80000918:	07c50513          	addi	a0,a0,124 # 8000f990 <tx_lock>
    8000091c:	34a000ef          	jal	80000c66 <release>
}
    80000920:	60a6                	ld	ra,72(sp)
    80000922:	6406                	ld	s0,64(sp)
    80000924:	74e2                	ld	s1,56(sp)
    80000926:	6ae2                	ld	s5,24(sp)
    80000928:	6161                	addi	sp,sp,80
    8000092a:	8082                	ret

000000008000092c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000092c:	1101                	addi	sp,sp,-32
    8000092e:	ec06                	sd	ra,24(sp)
    80000930:	e822                	sd	s0,16(sp)
    80000932:	e426                	sd	s1,8(sp)
    80000934:	1000                	addi	s0,sp,32
    80000936:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000938:	00007797          	auipc	a5,0x7
    8000093c:	f6c7a783          	lw	a5,-148(a5) # 800078a4 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	00007797          	auipc	a5,0x7
    80000946:	f5e7a783          	lw	a5,-162(a5) # 800078a0 <panicked>
    8000094a:	ef85                	bnez	a5,80000982 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000094c:	10000737          	lui	a4,0x10000
    80000950:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000952:	00074783          	lbu	a5,0(a4)
    80000956:	0207f793          	andi	a5,a5,32
    8000095a:	dfe5                	beqz	a5,80000952 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000095c:	0ff4f513          	zext.b	a0,s1
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000968:	00007797          	auipc	a5,0x7
    8000096c:	f3c7a783          	lw	a5,-196(a5) # 800078a4 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	212000ef          	jal	80000b8e <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	28e000ef          	jal	80000c12 <pop_off>
}
    80000988:	b7ed                	j	80000972 <uartputc_sync+0x46>

000000008000098a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000098a:	1141                	addi	sp,sp,-16
    8000098c:	e422                	sd	s0,8(sp)
    8000098e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000990:	100007b7          	lui	a5,0x10000
    80000994:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000996:	0007c783          	lbu	a5,0(a5)
    8000099a:	8b85                	andi	a5,a5,1
    8000099c:	cb81                	beqz	a5,800009ac <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a6:	6422                	ld	s0,8(sp)
    800009a8:	0141                	addi	sp,sp,16
    800009aa:	8082                	ret
    return -1;
    800009ac:	557d                	li	a0,-1
    800009ae:	bfe5                	j	800009a6 <uartgetc+0x1c>

00000000800009b0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009b0:	1101                	addi	sp,sp,-32
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e822                	sd	s0,16(sp)
    800009b6:	e426                	sd	s1,8(sp)
    800009b8:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009c0:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009c4:	0000f517          	auipc	a0,0xf
    800009c8:	fcc50513          	addi	a0,a0,-52 # 8000f990 <tx_lock>
    800009cc:	202000ef          	jal	80000bce <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009d6:	0007c783          	lbu	a5,0(a5)
    800009da:	0207f793          	andi	a5,a5,32
    800009de:	eb89                	bnez	a5,800009f0 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009e0:	0000f517          	auipc	a0,0xf
    800009e4:	fb050513          	addi	a0,a0,-80 # 8000f990 <tx_lock>
    800009e8:	27e000ef          	jal	80000c66 <release>

  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	00007797          	auipc	a5,0x7
    800009f4:	ea07ae23          	sw	zero,-324(a5) # 800078ac <tx_busy>
    wakeup(&tx_chan);
    800009f8:	00007517          	auipc	a0,0x7
    800009fc:	eb050513          	addi	a0,a0,-336 # 800078a8 <tx_chan>
    80000a00:	5d2010ef          	jal	80001fd2 <wakeup>
    80000a04:	bff1                	j	800009e0 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a06:	8a5ff0ef          	jal	800002aa <consoleintr>
    int c = uartgetc();
    80000a0a:	f81ff0ef          	jal	8000098a <uartgetc>
    if(c == -1)
    80000a0e:	fe951ce3          	bne	a0,s1,80000a06 <uartintr+0x56>
  }
}
    80000a12:	60e2                	ld	ra,24(sp)
    80000a14:	6442                	ld	s0,16(sp)
    80000a16:	64a2                	ld	s1,8(sp)
    80000a18:	6105                	addi	sp,sp,32
    80000a1a:	8082                	ret

0000000080000a1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1c:	1101                	addi	sp,sp,-32
    80000a1e:	ec06                	sd	ra,24(sp)
    80000a20:	e822                	sd	s0,16(sp)
    80000a22:	e426                	sd	s1,8(sp)
    80000a24:	e04a                	sd	s2,0(sp)
    80000a26:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a28:	03451793          	slli	a5,a0,0x34
    80000a2c:	e7a9                	bnez	a5,80000a76 <kfree+0x5a>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	00020797          	auipc	a5,0x20
    80000a34:	7a878793          	addi	a5,a5,1960 # 800211d8 <end>
    80000a38:	02f56f63          	bltu	a0,a5,80000a76 <kfree+0x5a>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	02f57b63          	bgeu	a0,a5,80000a76 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	25a000ef          	jal	80000ca2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	0000f917          	auipc	s2,0xf
    80000a50:	f5c90913          	addi	s2,s2,-164 # 8000f9a8 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	178000ef          	jal	80000bce <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a64:	854a                	mv	a0,s2
    80000a66:	200000ef          	jal	80000c66 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00006517          	auipc	a0,0x6
    80000a7a:	5c250513          	addi	a0,a0,1474 # 80007038 <etext+0x38>
    80000a7e:	d63ff0ef          	jal	800007e0 <panic>

0000000080000a82 <freerange>:
{
    80000a82:	7179                	addi	sp,sp,-48
    80000a84:	f406                	sd	ra,40(sp)
    80000a86:	f022                	sd	s0,32(sp)
    80000a88:	ec26                	sd	s1,24(sp)
    80000a8a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a8c:	6785                	lui	a5,0x1
    80000a8e:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a92:	00e504b3          	add	s1,a0,a4
    80000a96:	777d                	lui	a4,0xfffff
    80000a98:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94be                	add	s1,s1,a5
    80000a9c:	0295e263          	bltu	a1,s1,80000ac0 <freerange+0x3e>
    80000aa0:	e84a                	sd	s2,16(sp)
    80000aa2:	e44e                	sd	s3,8(sp)
    80000aa4:	e052                	sd	s4,0(sp)
    80000aa6:	892e                	mv	s2,a1
    kfree(p);
    80000aa8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aaa:	6985                	lui	s3,0x1
    kfree(p);
    80000aac:	01448533          	add	a0,s1,s4
    80000ab0:	f6dff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe997be3          	bgeu	s2,s1,80000aac <freerange+0x2a>
    80000aba:	6942                	ld	s2,16(sp)
    80000abc:	69a2                	ld	s3,8(sp)
    80000abe:	6a02                	ld	s4,0(sp)
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad2:	00006597          	auipc	a1,0x6
    80000ad6:	56e58593          	addi	a1,a1,1390 # 80007040 <etext+0x40>
    80000ada:	0000f517          	auipc	a0,0xf
    80000ade:	ece50513          	addi	a0,a0,-306 # 8000f9a8 <kmem>
    80000ae2:	06c000ef          	jal	80000b4e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	00020517          	auipc	a0,0x20
    80000aee:	6ee50513          	addi	a0,a0,1774 # 800211d8 <end>
    80000af2:	f91ff0ef          	jal	80000a82 <freerange>
}
    80000af6:	60a2                	ld	ra,8(sp)
    80000af8:	6402                	ld	s0,0(sp)
    80000afa:	0141                	addi	sp,sp,16
    80000afc:	8082                	ret

0000000080000afe <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afe:	1101                	addi	sp,sp,-32
    80000b00:	ec06                	sd	ra,24(sp)
    80000b02:	e822                	sd	s0,16(sp)
    80000b04:	e426                	sd	s1,8(sp)
    80000b06:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b08:	0000f497          	auipc	s1,0xf
    80000b0c:	ea048493          	addi	s1,s1,-352 # 8000f9a8 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0bc000ef          	jal	80000bce <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	0000f517          	auipc	a0,0xf
    80000b20:	e8c50513          	addi	a0,a0,-372 # 8000f9a8 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	140000ef          	jal	80000c66 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	172000ef          	jal	80000ca2 <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	0000f517          	auipc	a0,0xf
    80000b44:	e6850513          	addi	a0,a0,-408 # 8000f9a8 <kmem>
    80000b48:	11e000ef          	jal	80000c66 <release>
  if(r)
    80000b4c:	b7e5                	j	80000b34 <kalloc+0x36>

0000000080000b4e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b4e:	1141                	addi	sp,sp,-16
    80000b50:	e422                	sd	s0,8(sp)
    80000b52:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b5a:	00053823          	sd	zero,16(a0)
}
    80000b5e:	6422                	ld	s0,8(sp)
    80000b60:	0141                	addi	sp,sp,16
    80000b62:	8082                	ret

0000000080000b64 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b64:	411c                	lw	a5,0(a0)
    80000b66:	e399                	bnez	a5,80000b6c <holding+0x8>
    80000b68:	4501                	li	a0,0
  return r;
}
    80000b6a:	8082                	ret
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b76:	6904                	ld	s1,16(a0)
    80000b78:	53b000ef          	jal	800018b2 <mycpu>
    80000b7c:	40a48533          	sub	a0,s1,a0
    80000b80:	00153513          	seqz	a0,a0
}
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret

0000000080000b8e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b98:	100024f3          	csrr	s1,sstatus
    80000b9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ba0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ba2:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000ba6:	50d000ef          	jal	800018b2 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cb99                	beqz	a5,80000bc2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	505000ef          	jal	800018b2 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	4f1000ef          	jal	800018b2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc6:	8085                	srli	s1,s1,0x1
    80000bc8:	8885                	andi	s1,s1,1
    80000bca:	dd64                	sw	s1,124(a0)
    80000bcc:	b7cd                	j	80000bae <push_off+0x20>

0000000080000bce <acquire>:
{
    80000bce:	1101                	addi	sp,sp,-32
    80000bd0:	ec06                	sd	ra,24(sp)
    80000bd2:	e822                	sd	s0,16(sp)
    80000bd4:	e426                	sd	s1,8(sp)
    80000bd6:	1000                	addi	s0,sp,32
    80000bd8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bda:	fb5ff0ef          	jal	80000b8e <push_off>
  if(holding(lk))
    80000bde:	8526                	mv	a0,s1
    80000be0:	f85ff0ef          	jal	80000b64 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	4705                	li	a4,1
  if(holding(lk))
    80000be6:	e105                	bnez	a0,80000c06 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be8:	87ba                	mv	a5,a4
    80000bea:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bee:	2781                	sext.w	a5,a5
    80000bf0:	ffe5                	bnez	a5,80000be8 <acquire+0x1a>
  __sync_synchronize();
    80000bf2:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf6:	4bd000ef          	jal	800018b2 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00006517          	auipc	a0,0x6
    80000c0a:	44250513          	addi	a0,a0,1090 # 80007048 <etext+0x48>
    80000c0e:	bd3ff0ef          	jal	800007e0 <panic>

0000000080000c12 <pop_off>:

void
pop_off(void)
{
    80000c12:	1141                	addi	sp,sp,-16
    80000c14:	e406                	sd	ra,8(sp)
    80000c16:	e022                	sd	s0,0(sp)
    80000c18:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1a:	499000ef          	jal	800018b2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c22:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c24:	e78d                	bnez	a5,80000c4e <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c26:	5d3c                	lw	a5,120(a0)
    80000c28:	02f05963          	blez	a5,80000c5a <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c2c:	37fd                	addiw	a5,a5,-1
    80000c2e:	0007871b          	sext.w	a4,a5
    80000c32:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c34:	eb09                	bnez	a4,80000c46 <pop_off+0x34>
    80000c36:	5d7c                	lw	a5,124(a0)
    80000c38:	c799                	beqz	a5,80000c46 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c42:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c46:	60a2                	ld	ra,8(sp)
    80000c48:	6402                	ld	s0,0(sp)
    80000c4a:	0141                	addi	sp,sp,16
    80000c4c:	8082                	ret
    panic("pop_off - interruptible");
    80000c4e:	00006517          	auipc	a0,0x6
    80000c52:	40250513          	addi	a0,a0,1026 # 80007050 <etext+0x50>
    80000c56:	b8bff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000c5a:	00006517          	auipc	a0,0x6
    80000c5e:	40e50513          	addi	a0,a0,1038 # 80007068 <etext+0x68>
    80000c62:	b7fff0ef          	jal	800007e0 <panic>

0000000080000c66 <release>:
{
    80000c66:	1101                	addi	sp,sp,-32
    80000c68:	ec06                	sd	ra,24(sp)
    80000c6a:	e822                	sd	s0,16(sp)
    80000c6c:	e426                	sd	s1,8(sp)
    80000c6e:	1000                	addi	s0,sp,32
    80000c70:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c72:	ef3ff0ef          	jal	80000b64 <holding>
    80000c76:	c105                	beqz	a0,80000c96 <release+0x30>
  lk->cpu = 0;
    80000c78:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c7c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c80:	0f50000f          	fence	iorw,ow
    80000c84:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c88:	f8bff0ef          	jal	80000c12 <pop_off>
}
    80000c8c:	60e2                	ld	ra,24(sp)
    80000c8e:	6442                	ld	s0,16(sp)
    80000c90:	64a2                	ld	s1,8(sp)
    80000c92:	6105                	addi	sp,sp,32
    80000c94:	8082                	ret
    panic("release");
    80000c96:	00006517          	auipc	a0,0x6
    80000c9a:	3da50513          	addi	a0,a0,986 # 80007070 <etext+0x70>
    80000c9e:	b43ff0ef          	jal	800007e0 <panic>

0000000080000ca2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ca2:	1141                	addi	sp,sp,-16
    80000ca4:	e422                	sd	s0,8(sp)
    80000ca6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ca8:	ca19                	beqz	a2,80000cbe <memset+0x1c>
    80000caa:	87aa                	mv	a5,a0
    80000cac:	1602                	slli	a2,a2,0x20
    80000cae:	9201                	srli	a2,a2,0x20
    80000cb0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cb4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cb8:	0785                	addi	a5,a5,1
    80000cba:	fee79de3          	bne	a5,a4,80000cb4 <memset+0x12>
  }
  return dst;
}
    80000cbe:	6422                	ld	s0,8(sp)
    80000cc0:	0141                	addi	sp,sp,16
    80000cc2:	8082                	ret

0000000080000cc4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cc4:	1141                	addi	sp,sp,-16
    80000cc6:	e422                	sd	s0,8(sp)
    80000cc8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cca:	ca05                	beqz	a2,80000cfa <memcmp+0x36>
    80000ccc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cd0:	1682                	slli	a3,a3,0x20
    80000cd2:	9281                	srli	a3,a3,0x20
    80000cd4:	0685                	addi	a3,a3,1
    80000cd6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cd8:	00054783          	lbu	a5,0(a0)
    80000cdc:	0005c703          	lbu	a4,0(a1)
    80000ce0:	00e79863          	bne	a5,a4,80000cf0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ce4:	0505                	addi	a0,a0,1
    80000ce6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ce8:	fed518e3          	bne	a0,a3,80000cd8 <memcmp+0x14>
  }

  return 0;
    80000cec:	4501                	li	a0,0
    80000cee:	a019                	j	80000cf4 <memcmp+0x30>
      return *s1 - *s2;
    80000cf0:	40e7853b          	subw	a0,a5,a4
}
    80000cf4:	6422                	ld	s0,8(sp)
    80000cf6:	0141                	addi	sp,sp,16
    80000cf8:	8082                	ret
  return 0;
    80000cfa:	4501                	li	a0,0
    80000cfc:	bfe5                	j	80000cf4 <memcmp+0x30>

0000000080000cfe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000cfe:	1141                	addi	sp,sp,-16
    80000d00:	e422                	sd	s0,8(sp)
    80000d02:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d04:	c205                	beqz	a2,80000d24 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d06:	02a5e263          	bltu	a1,a0,80000d2a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d0a:	1602                	slli	a2,a2,0x20
    80000d0c:	9201                	srli	a2,a2,0x20
    80000d0e:	00c587b3          	add	a5,a1,a2
{
    80000d12:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d14:	0585                	addi	a1,a1,1
    80000d16:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdde29>
    80000d18:	fff5c683          	lbu	a3,-1(a1)
    80000d1c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d20:	feb79ae3          	bne	a5,a1,80000d14 <memmove+0x16>

  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  if(s < d && s + n > d){
    80000d2a:	02061693          	slli	a3,a2,0x20
    80000d2e:	9281                	srli	a3,a3,0x20
    80000d30:	00d58733          	add	a4,a1,a3
    80000d34:	fce57be3          	bgeu	a0,a4,80000d0a <memmove+0xc>
    d += n;
    80000d38:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d3a:	fff6079b          	addiw	a5,a2,-1
    80000d3e:	1782                	slli	a5,a5,0x20
    80000d40:	9381                	srli	a5,a5,0x20
    80000d42:	fff7c793          	not	a5,a5
    80000d46:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d48:	177d                	addi	a4,a4,-1
    80000d4a:	16fd                	addi	a3,a3,-1
    80000d4c:	00074603          	lbu	a2,0(a4)
    80000d50:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d54:	fef71ae3          	bne	a4,a5,80000d48 <memmove+0x4a>
    80000d58:	b7f1                	j	80000d24 <memmove+0x26>

0000000080000d5a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d5a:	1141                	addi	sp,sp,-16
    80000d5c:	e406                	sd	ra,8(sp)
    80000d5e:	e022                	sd	s0,0(sp)
    80000d60:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d62:	f9dff0ef          	jal	80000cfe <memmove>
}
    80000d66:	60a2                	ld	ra,8(sp)
    80000d68:	6402                	ld	s0,0(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret

0000000080000d6e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d74:	ce11                	beqz	a2,80000d90 <strncmp+0x22>
    80000d76:	00054783          	lbu	a5,0(a0)
    80000d7a:	cf89                	beqz	a5,80000d94 <strncmp+0x26>
    80000d7c:	0005c703          	lbu	a4,0(a1)
    80000d80:	00f71a63          	bne	a4,a5,80000d94 <strncmp+0x26>
    n--, p++, q++;
    80000d84:	367d                	addiw	a2,a2,-1
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d8a:	f675                	bnez	a2,80000d76 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	a801                	j	80000d9e <strncmp+0x30>
    80000d90:	4501                	li	a0,0
    80000d92:	a031                	j	80000d9e <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000d94:	00054503          	lbu	a0,0(a0)
    80000d98:	0005c783          	lbu	a5,0(a1)
    80000d9c:	9d1d                	subw	a0,a0,a5
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret

0000000080000da4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000da4:	1141                	addi	sp,sp,-16
    80000da6:	e422                	sd	s0,8(sp)
    80000da8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000daa:	87aa                	mv	a5,a0
    80000dac:	86b2                	mv	a3,a2
    80000dae:	367d                	addiw	a2,a2,-1
    80000db0:	02d05563          	blez	a3,80000dda <strncpy+0x36>
    80000db4:	0785                	addi	a5,a5,1
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	fee78fa3          	sb	a4,-1(a5)
    80000dbe:	0585                	addi	a1,a1,1
    80000dc0:	f775                	bnez	a4,80000dac <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dc2:	873e                	mv	a4,a5
    80000dc4:	9fb5                	addw	a5,a5,a3
    80000dc6:	37fd                	addiw	a5,a5,-1
    80000dc8:	00c05963          	blez	a2,80000dda <strncpy+0x36>
    *s++ = 0;
    80000dcc:	0705                	addi	a4,a4,1
    80000dce:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000dd2:	40e786bb          	subw	a3,a5,a4
    80000dd6:	fed04be3          	bgtz	a3,80000dcc <strncpy+0x28>
  return os;
}
    80000dda:	6422                	ld	s0,8(sp)
    80000ddc:	0141                	addi	sp,sp,16
    80000dde:	8082                	ret

0000000080000de0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000de6:	02c05363          	blez	a2,80000e0c <safestrcpy+0x2c>
    80000dea:	fff6069b          	addiw	a3,a2,-1
    80000dee:	1682                	slli	a3,a3,0x20
    80000df0:	9281                	srli	a3,a3,0x20
    80000df2:	96ae                	add	a3,a3,a1
    80000df4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000df6:	00d58963          	beq	a1,a3,80000e08 <safestrcpy+0x28>
    80000dfa:	0585                	addi	a1,a1,1
    80000dfc:	0785                	addi	a5,a5,1
    80000dfe:	fff5c703          	lbu	a4,-1(a1)
    80000e02:	fee78fa3          	sb	a4,-1(a5)
    80000e06:	fb65                	bnez	a4,80000df6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e08:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret

0000000080000e12 <strlen>:

int
strlen(const char *s)
{
    80000e12:	1141                	addi	sp,sp,-16
    80000e14:	e422                	sd	s0,8(sp)
    80000e16:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e18:	00054783          	lbu	a5,0(a0)
    80000e1c:	cf91                	beqz	a5,80000e38 <strlen+0x26>
    80000e1e:	0505                	addi	a0,a0,1
    80000e20:	87aa                	mv	a5,a0
    80000e22:	86be                	mv	a3,a5
    80000e24:	0785                	addi	a5,a5,1
    80000e26:	fff7c703          	lbu	a4,-1(a5)
    80000e2a:	ff65                	bnez	a4,80000e22 <strlen+0x10>
    80000e2c:	40a6853b          	subw	a0,a3,a0
    80000e30:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <strlen+0x20>

0000000080000e3c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e406                	sd	ra,8(sp)
    80000e40:	e022                	sd	s0,0(sp)
    80000e42:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e44:	25f000ef          	jal	800018a2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e48:	00007717          	auipc	a4,0x7
    80000e4c:	a6870713          	addi	a4,a4,-1432 # 800078b0 <started>
  if(cpuid() == 0){
    80000e50:	c51d                	beqz	a0,80000e7e <main+0x42>
    while(started == 0)
    80000e52:	431c                	lw	a5,0(a4)
    80000e54:	2781                	sext.w	a5,a5
    80000e56:	dff5                	beqz	a5,80000e52 <main+0x16>
      ;
    __sync_synchronize();
    80000e58:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e5c:	247000ef          	jal	800018a2 <cpuid>
    80000e60:	85aa                	mv	a1,a0
    80000e62:	00006517          	auipc	a0,0x6
    80000e66:	23650513          	addi	a0,a0,566 # 80007098 <etext+0x98>
    80000e6a:	e90ff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000e6e:	080000ef          	jal	80000eee <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e72:	63e010ef          	jal	800024b0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e76:	632040ef          	jal	800054a8 <plicinithart>
  }

  scheduler();        
    80000e7a:	6c9000ef          	jal	80001d42 <scheduler>
    consoleinit();
    80000e7e:	da6ff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000e82:	99bff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000e86:	00006517          	auipc	a0,0x6
    80000e8a:	1f250513          	addi	a0,a0,498 # 80007078 <etext+0x78>
    80000e8e:	e6cff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000e92:	00006517          	auipc	a0,0x6
    80000e96:	1ee50513          	addi	a0,a0,494 # 80007080 <etext+0x80>
    80000e9a:	e60ff0ef          	jal	800004fa <printf>
    printf("\n");
    80000e9e:	00006517          	auipc	a0,0x6
    80000ea2:	1da50513          	addi	a0,a0,474 # 80007078 <etext+0x78>
    80000ea6:	e54ff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000eaa:	c21ff0ef          	jal	80000aca <kinit>
    kvminit();       // create kernel page table
    80000eae:	2ca000ef          	jal	80001178 <kvminit>
    kvminithart();   // turn on paging
    80000eb2:	03c000ef          	jal	80000eee <kvminithart>
    procinit();      // process table
    80000eb6:	137000ef          	jal	800017ec <procinit>
    trapinit();      // trap vectors
    80000eba:	5d2010ef          	jal	8000248c <trapinit>
    trapinithart();  // install kernel trap vector
    80000ebe:	5f2010ef          	jal	800024b0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ec2:	5cc040ef          	jal	8000548e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ec6:	5e2040ef          	jal	800054a8 <plicinithart>
    binit();         // buffer cache
    80000eca:	4b3010ef          	jal	80002b7c <binit>
    iinit();         // inode table
    80000ece:	238020ef          	jal	80003106 <iinit>
    fileinit();      // file table
    80000ed2:	12a030ef          	jal	80003ffc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ed6:	6c2040ef          	jal	80005598 <virtio_disk_init>
    userinit();      // first user process
    80000eda:	4cf000ef          	jal	80001ba8 <userinit>
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    started = 1;
    80000ee2:	4785                	li	a5,1
    80000ee4:	00007717          	auipc	a4,0x7
    80000ee8:	9cf72623          	sw	a5,-1588(a4) # 800078b0 <started>
    80000eec:	b779                	j	80000e7a <main+0x3e>

0000000080000eee <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000eee:	1141                	addi	sp,sp,-16
    80000ef0:	e422                	sd	s0,8(sp)
    80000ef2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ef4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ef8:	00007797          	auipc	a5,0x7
    80000efc:	9c07b783          	ld	a5,-1600(a5) # 800078b8 <kernel_pagetable>
    80000f00:	83b1                	srli	a5,a5,0xc
    80000f02:	577d                	li	a4,-1
    80000f04:	177e                	slli	a4,a4,0x3f
    80000f06:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f08:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f0c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret

0000000080000f16 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f16:	7139                	addi	sp,sp,-64
    80000f18:	fc06                	sd	ra,56(sp)
    80000f1a:	f822                	sd	s0,48(sp)
    80000f1c:	f426                	sd	s1,40(sp)
    80000f1e:	f04a                	sd	s2,32(sp)
    80000f20:	ec4e                	sd	s3,24(sp)
    80000f22:	e852                	sd	s4,16(sp)
    80000f24:	e456                	sd	s5,8(sp)
    80000f26:	e05a                	sd	s6,0(sp)
    80000f28:	0080                	addi	s0,sp,64
    80000f2a:	84aa                	mv	s1,a0
    80000f2c:	89ae                	mv	s3,a1
    80000f2e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f30:	57fd                	li	a5,-1
    80000f32:	83e9                	srli	a5,a5,0x1a
    80000f34:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f36:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f38:	02b7fc63          	bgeu	a5,a1,80000f70 <walk+0x5a>
    panic("walk");
    80000f3c:	00006517          	auipc	a0,0x6
    80000f40:	17450513          	addi	a0,a0,372 # 800070b0 <etext+0xb0>
    80000f44:	89dff0ef          	jal	800007e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f48:	060a8263          	beqz	s5,80000fac <walk+0x96>
    80000f4c:	bb3ff0ef          	jal	80000afe <kalloc>
    80000f50:	84aa                	mv	s1,a0
    80000f52:	c139                	beqz	a0,80000f98 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f54:	6605                	lui	a2,0x1
    80000f56:	4581                	li	a1,0
    80000f58:	d4bff0ef          	jal	80000ca2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f5c:	00c4d793          	srli	a5,s1,0xc
    80000f60:	07aa                	slli	a5,a5,0xa
    80000f62:	0017e793          	ori	a5,a5,1
    80000f66:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000f6a:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdde1f>
    80000f6c:	036a0063          	beq	s4,s6,80000f8c <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000f70:	0149d933          	srl	s2,s3,s4
    80000f74:	1ff97913          	andi	s2,s2,511
    80000f78:	090e                	slli	s2,s2,0x3
    80000f7a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000f7c:	00093483          	ld	s1,0(s2)
    80000f80:	0014f793          	andi	a5,s1,1
    80000f84:	d3f1                	beqz	a5,80000f48 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000f86:	80a9                	srli	s1,s1,0xa
    80000f88:	04b2                	slli	s1,s1,0xc
    80000f8a:	b7c5                	j	80000f6a <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000f8c:	00c9d513          	srli	a0,s3,0xc
    80000f90:	1ff57513          	andi	a0,a0,511
    80000f94:	050e                	slli	a0,a0,0x3
    80000f96:	9526                	add	a0,a0,s1
}
    80000f98:	70e2                	ld	ra,56(sp)
    80000f9a:	7442                	ld	s0,48(sp)
    80000f9c:	74a2                	ld	s1,40(sp)
    80000f9e:	7902                	ld	s2,32(sp)
    80000fa0:	69e2                	ld	s3,24(sp)
    80000fa2:	6a42                	ld	s4,16(sp)
    80000fa4:	6aa2                	ld	s5,8(sp)
    80000fa6:	6b02                	ld	s6,0(sp)
    80000fa8:	6121                	addi	sp,sp,64
    80000faa:	8082                	ret
        return 0;
    80000fac:	4501                	li	a0,0
    80000fae:	b7ed                	j	80000f98 <walk+0x82>

0000000080000fb0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fb0:	57fd                	li	a5,-1
    80000fb2:	83e9                	srli	a5,a5,0x1a
    80000fb4:	00b7f463          	bgeu	a5,a1,80000fbc <walkaddr+0xc>
    return 0;
    80000fb8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000fba:	8082                	ret
{
    80000fbc:	1141                	addi	sp,sp,-16
    80000fbe:	e406                	sd	ra,8(sp)
    80000fc0:	e022                	sd	s0,0(sp)
    80000fc2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000fc4:	4601                	li	a2,0
    80000fc6:	f51ff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    80000fca:	c105                	beqz	a0,80000fea <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000fcc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000fce:	0117f693          	andi	a3,a5,17
    80000fd2:	4745                	li	a4,17
    return 0;
    80000fd4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000fd6:	00e68663          	beq	a3,a4,80000fe2 <walkaddr+0x32>
}
    80000fda:	60a2                	ld	ra,8(sp)
    80000fdc:	6402                	ld	s0,0(sp)
    80000fde:	0141                	addi	sp,sp,16
    80000fe0:	8082                	ret
  pa = PTE2PA(*pte);
    80000fe2:	83a9                	srli	a5,a5,0xa
    80000fe4:	00c79513          	slli	a0,a5,0xc
  return pa;
    80000fe8:	bfcd                	j	80000fda <walkaddr+0x2a>
    return 0;
    80000fea:	4501                	li	a0,0
    80000fec:	b7fd                	j	80000fda <walkaddr+0x2a>

0000000080000fee <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80000fee:	715d                	addi	sp,sp,-80
    80000ff0:	e486                	sd	ra,72(sp)
    80000ff2:	e0a2                	sd	s0,64(sp)
    80000ff4:	fc26                	sd	s1,56(sp)
    80000ff6:	f84a                	sd	s2,48(sp)
    80000ff8:	f44e                	sd	s3,40(sp)
    80000ffa:	f052                	sd	s4,32(sp)
    80000ffc:	ec56                	sd	s5,24(sp)
    80000ffe:	e85a                	sd	s6,16(sp)
    80001000:	e45e                	sd	s7,8(sp)
    80001002:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001004:	03459793          	slli	a5,a1,0x34
    80001008:	e7a9                	bnez	a5,80001052 <mappages+0x64>
    8000100a:	8aaa                	mv	s5,a0
    8000100c:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000100e:	03461793          	slli	a5,a2,0x34
    80001012:	e7b1                	bnez	a5,8000105e <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80001014:	ca39                	beqz	a2,8000106a <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001016:	77fd                	lui	a5,0xfffff
    80001018:	963e                	add	a2,a2,a5
    8000101a:	00b609b3          	add	s3,a2,a1
  a = va;
    8000101e:	892e                	mv	s2,a1
    80001020:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001024:	6b85                	lui	s7,0x1
    80001026:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    8000102a:	4605                	li	a2,1
    8000102c:	85ca                	mv	a1,s2
    8000102e:	8556                	mv	a0,s5
    80001030:	ee7ff0ef          	jal	80000f16 <walk>
    80001034:	c539                	beqz	a0,80001082 <mappages+0x94>
    if(*pte & PTE_V)
    80001036:	611c                	ld	a5,0(a0)
    80001038:	8b85                	andi	a5,a5,1
    8000103a:	ef95                	bnez	a5,80001076 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000103c:	80b1                	srli	s1,s1,0xc
    8000103e:	04aa                	slli	s1,s1,0xa
    80001040:	0164e4b3          	or	s1,s1,s6
    80001044:	0014e493          	ori	s1,s1,1
    80001048:	e104                	sd	s1,0(a0)
    if(a == last)
    8000104a:	05390863          	beq	s2,s3,8000109a <mappages+0xac>
    a += PGSIZE;
    8000104e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001050:	bfd9                	j	80001026 <mappages+0x38>
    panic("mappages: va not aligned");
    80001052:	00006517          	auipc	a0,0x6
    80001056:	06650513          	addi	a0,a0,102 # 800070b8 <etext+0xb8>
    8000105a:	f86ff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    8000105e:	00006517          	auipc	a0,0x6
    80001062:	07a50513          	addi	a0,a0,122 # 800070d8 <etext+0xd8>
    80001066:	f7aff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    8000106a:	00006517          	auipc	a0,0x6
    8000106e:	08e50513          	addi	a0,a0,142 # 800070f8 <etext+0xf8>
    80001072:	f6eff0ef          	jal	800007e0 <panic>
      panic("mappages: remap");
    80001076:	00006517          	auipc	a0,0x6
    8000107a:	09250513          	addi	a0,a0,146 # 80007108 <etext+0x108>
    8000107e:	f62ff0ef          	jal	800007e0 <panic>
      return -1;
    80001082:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001084:	60a6                	ld	ra,72(sp)
    80001086:	6406                	ld	s0,64(sp)
    80001088:	74e2                	ld	s1,56(sp)
    8000108a:	7942                	ld	s2,48(sp)
    8000108c:	79a2                	ld	s3,40(sp)
    8000108e:	7a02                	ld	s4,32(sp)
    80001090:	6ae2                	ld	s5,24(sp)
    80001092:	6b42                	ld	s6,16(sp)
    80001094:	6ba2                	ld	s7,8(sp)
    80001096:	6161                	addi	sp,sp,80
    80001098:	8082                	ret
  return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7e5                	j	80001084 <mappages+0x96>

000000008000109e <kvmmap>:
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
    800010a6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010a8:	86b2                	mv	a3,a2
    800010aa:	863e                	mv	a2,a5
    800010ac:	f43ff0ef          	jal	80000fee <mappages>
    800010b0:	e509                	bnez	a0,800010ba <kvmmap+0x1c>
}
    800010b2:	60a2                	ld	ra,8(sp)
    800010b4:	6402                	ld	s0,0(sp)
    800010b6:	0141                	addi	sp,sp,16
    800010b8:	8082                	ret
    panic("kvmmap");
    800010ba:	00006517          	auipc	a0,0x6
    800010be:	05e50513          	addi	a0,a0,94 # 80007118 <etext+0x118>
    800010c2:	f1eff0ef          	jal	800007e0 <panic>

00000000800010c6 <kvmmake>:
{
    800010c6:	1101                	addi	sp,sp,-32
    800010c8:	ec06                	sd	ra,24(sp)
    800010ca:	e822                	sd	s0,16(sp)
    800010cc:	e426                	sd	s1,8(sp)
    800010ce:	e04a                	sd	s2,0(sp)
    800010d0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800010d2:	a2dff0ef          	jal	80000afe <kalloc>
    800010d6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800010d8:	6605                	lui	a2,0x1
    800010da:	4581                	li	a1,0
    800010dc:	bc7ff0ef          	jal	80000ca2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800010e0:	4719                	li	a4,6
    800010e2:	6685                	lui	a3,0x1
    800010e4:	10000637          	lui	a2,0x10000
    800010e8:	100005b7          	lui	a1,0x10000
    800010ec:	8526                	mv	a0,s1
    800010ee:	fb1ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800010f2:	4719                	li	a4,6
    800010f4:	6685                	lui	a3,0x1
    800010f6:	10001637          	lui	a2,0x10001
    800010fa:	100015b7          	lui	a1,0x10001
    800010fe:	8526                	mv	a0,s1
    80001100:	f9fff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001104:	4719                	li	a4,6
    80001106:	040006b7          	lui	a3,0x4000
    8000110a:	0c000637          	lui	a2,0xc000
    8000110e:	0c0005b7          	lui	a1,0xc000
    80001112:	8526                	mv	a0,s1
    80001114:	f8bff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001118:	00006917          	auipc	s2,0x6
    8000111c:	ee890913          	addi	s2,s2,-280 # 80007000 <etext>
    80001120:	4729                	li	a4,10
    80001122:	80006697          	auipc	a3,0x80006
    80001126:	ede68693          	addi	a3,a3,-290 # 7000 <_entry-0x7fff9000>
    8000112a:	4605                	li	a2,1
    8000112c:	067e                	slli	a2,a2,0x1f
    8000112e:	85b2                	mv	a1,a2
    80001130:	8526                	mv	a0,s1
    80001132:	f6dff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001136:	46c5                	li	a3,17
    80001138:	06ee                	slli	a3,a3,0x1b
    8000113a:	4719                	li	a4,6
    8000113c:	412686b3          	sub	a3,a3,s2
    80001140:	864a                	mv	a2,s2
    80001142:	85ca                	mv	a1,s2
    80001144:	8526                	mv	a0,s1
    80001146:	f59ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000114a:	4729                	li	a4,10
    8000114c:	6685                	lui	a3,0x1
    8000114e:	00005617          	auipc	a2,0x5
    80001152:	eb260613          	addi	a2,a2,-334 # 80006000 <_trampoline>
    80001156:	040005b7          	lui	a1,0x4000
    8000115a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000115c:	05b2                	slli	a1,a1,0xc
    8000115e:	8526                	mv	a0,s1
    80001160:	f3fff0ef          	jal	8000109e <kvmmap>
  proc_mapstacks(kpgtbl);
    80001164:	8526                	mv	a0,s1
    80001166:	5ee000ef          	jal	80001754 <proc_mapstacks>
}
    8000116a:	8526                	mv	a0,s1
    8000116c:	60e2                	ld	ra,24(sp)
    8000116e:	6442                	ld	s0,16(sp)
    80001170:	64a2                	ld	s1,8(sp)
    80001172:	6902                	ld	s2,0(sp)
    80001174:	6105                	addi	sp,sp,32
    80001176:	8082                	ret

0000000080001178 <kvminit>:
{
    80001178:	1141                	addi	sp,sp,-16
    8000117a:	e406                	sd	ra,8(sp)
    8000117c:	e022                	sd	s0,0(sp)
    8000117e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001180:	f47ff0ef          	jal	800010c6 <kvmmake>
    80001184:	00006797          	auipc	a5,0x6
    80001188:	72a7ba23          	sd	a0,1844(a5) # 800078b8 <kernel_pagetable>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret

0000000080001194 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001194:	1101                	addi	sp,sp,-32
    80001196:	ec06                	sd	ra,24(sp)
    80001198:	e822                	sd	s0,16(sp)
    8000119a:	e426                	sd	s1,8(sp)
    8000119c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000119e:	961ff0ef          	jal	80000afe <kalloc>
    800011a2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011a4:	c509                	beqz	a0,800011ae <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	af9ff0ef          	jal	80000ca2 <memset>
  return pagetable;
}
    800011ae:	8526                	mv	a0,s1
    800011b0:	60e2                	ld	ra,24(sp)
    800011b2:	6442                	ld	s0,16(sp)
    800011b4:	64a2                	ld	s1,8(sp)
    800011b6:	6105                	addi	sp,sp,32
    800011b8:	8082                	ret

00000000800011ba <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011ba:	7139                	addi	sp,sp,-64
    800011bc:	fc06                	sd	ra,56(sp)
    800011be:	f822                	sd	s0,48(sp)
    800011c0:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011c2:	03459793          	slli	a5,a1,0x34
    800011c6:	e38d                	bnez	a5,800011e8 <uvmunmap+0x2e>
    800011c8:	f04a                	sd	s2,32(sp)
    800011ca:	ec4e                	sd	s3,24(sp)
    800011cc:	e852                	sd	s4,16(sp)
    800011ce:	e456                	sd	s5,8(sp)
    800011d0:	e05a                	sd	s6,0(sp)
    800011d2:	8a2a                	mv	s4,a0
    800011d4:	892e                	mv	s2,a1
    800011d6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800011d8:	0632                	slli	a2,a2,0xc
    800011da:	00b609b3          	add	s3,a2,a1
    800011de:	6b05                	lui	s6,0x1
    800011e0:	0535f963          	bgeu	a1,s3,80001232 <uvmunmap+0x78>
    800011e4:	f426                	sd	s1,40(sp)
    800011e6:	a015                	j	8000120a <uvmunmap+0x50>
    800011e8:	f426                	sd	s1,40(sp)
    800011ea:	f04a                	sd	s2,32(sp)
    800011ec:	ec4e                	sd	s3,24(sp)
    800011ee:	e852                	sd	s4,16(sp)
    800011f0:	e456                	sd	s5,8(sp)
    800011f2:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    800011f4:	00006517          	auipc	a0,0x6
    800011f8:	f2c50513          	addi	a0,a0,-212 # 80007120 <etext+0x120>
    800011fc:	de4ff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001200:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001204:	995a                	add	s2,s2,s6
    80001206:	03397563          	bgeu	s2,s3,80001230 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    8000120a:	4601                	li	a2,0
    8000120c:	85ca                	mv	a1,s2
    8000120e:	8552                	mv	a0,s4
    80001210:	d07ff0ef          	jal	80000f16 <walk>
    80001214:	84aa                	mv	s1,a0
    80001216:	d57d                	beqz	a0,80001204 <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001218:	611c                	ld	a5,0(a0)
    8000121a:	0017f713          	andi	a4,a5,1
    8000121e:	d37d                	beqz	a4,80001204 <uvmunmap+0x4a>
    if(do_free){
    80001220:	fe0a80e3          	beqz	s5,80001200 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    80001224:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001226:	00c79513          	slli	a0,a5,0xc
    8000122a:	ff2ff0ef          	jal	80000a1c <kfree>
    8000122e:	bfc9                	j	80001200 <uvmunmap+0x46>
    80001230:	74a2                	ld	s1,40(sp)
    80001232:	7902                	ld	s2,32(sp)
    80001234:	69e2                	ld	s3,24(sp)
    80001236:	6a42                	ld	s4,16(sp)
    80001238:	6aa2                	ld	s5,8(sp)
    8000123a:	6b02                	ld	s6,0(sp)
  }
}
    8000123c:	70e2                	ld	ra,56(sp)
    8000123e:	7442                	ld	s0,48(sp)
    80001240:	6121                	addi	sp,sp,64
    80001242:	8082                	ret

0000000080001244 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001244:	1101                	addi	sp,sp,-32
    80001246:	ec06                	sd	ra,24(sp)
    80001248:	e822                	sd	s0,16(sp)
    8000124a:	e426                	sd	s1,8(sp)
    8000124c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000124e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001250:	00b67d63          	bgeu	a2,a1,8000126a <uvmdealloc+0x26>
    80001254:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001256:	6785                	lui	a5,0x1
    80001258:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000125a:	00f60733          	add	a4,a2,a5
    8000125e:	76fd                	lui	a3,0xfffff
    80001260:	8f75                	and	a4,a4,a3
    80001262:	97ae                	add	a5,a5,a1
    80001264:	8ff5                	and	a5,a5,a3
    80001266:	00f76863          	bltu	a4,a5,80001276 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000126a:	8526                	mv	a0,s1
    8000126c:	60e2                	ld	ra,24(sp)
    8000126e:	6442                	ld	s0,16(sp)
    80001270:	64a2                	ld	s1,8(sp)
    80001272:	6105                	addi	sp,sp,32
    80001274:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001276:	8f99                	sub	a5,a5,a4
    80001278:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000127a:	4685                	li	a3,1
    8000127c:	0007861b          	sext.w	a2,a5
    80001280:	85ba                	mv	a1,a4
    80001282:	f39ff0ef          	jal	800011ba <uvmunmap>
    80001286:	b7d5                	j	8000126a <uvmdealloc+0x26>

0000000080001288 <uvmalloc>:
  if(newsz < oldsz)
    80001288:	08b66f63          	bltu	a2,a1,80001326 <uvmalloc+0x9e>
{
    8000128c:	7139                	addi	sp,sp,-64
    8000128e:	fc06                	sd	ra,56(sp)
    80001290:	f822                	sd	s0,48(sp)
    80001292:	ec4e                	sd	s3,24(sp)
    80001294:	e852                	sd	s4,16(sp)
    80001296:	e456                	sd	s5,8(sp)
    80001298:	0080                	addi	s0,sp,64
    8000129a:	8aaa                	mv	s5,a0
    8000129c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000129e:	6785                	lui	a5,0x1
    800012a0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012a2:	95be                	add	a1,a1,a5
    800012a4:	77fd                	lui	a5,0xfffff
    800012a6:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012aa:	08c9f063          	bgeu	s3,a2,8000132a <uvmalloc+0xa2>
    800012ae:	f426                	sd	s1,40(sp)
    800012b0:	f04a                	sd	s2,32(sp)
    800012b2:	e05a                	sd	s6,0(sp)
    800012b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012ba:	845ff0ef          	jal	80000afe <kalloc>
    800012be:	84aa                	mv	s1,a0
    if(mem == 0){
    800012c0:	c515                	beqz	a0,800012ec <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012c2:	6605                	lui	a2,0x1
    800012c4:	4581                	li	a1,0
    800012c6:	9ddff0ef          	jal	80000ca2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012ca:	875a                	mv	a4,s6
    800012cc:	86a6                	mv	a3,s1
    800012ce:	6605                	lui	a2,0x1
    800012d0:	85ca                	mv	a1,s2
    800012d2:	8556                	mv	a0,s5
    800012d4:	d1bff0ef          	jal	80000fee <mappages>
    800012d8:	e915                	bnez	a0,8000130c <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012da:	6785                	lui	a5,0x1
    800012dc:	993e                	add	s2,s2,a5
    800012de:	fd496ee3          	bltu	s2,s4,800012ba <uvmalloc+0x32>
  return newsz;
    800012e2:	8552                	mv	a0,s4
    800012e4:	74a2                	ld	s1,40(sp)
    800012e6:	7902                	ld	s2,32(sp)
    800012e8:	6b02                	ld	s6,0(sp)
    800012ea:	a811                	j	800012fe <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    800012ec:	864e                	mv	a2,s3
    800012ee:	85ca                	mv	a1,s2
    800012f0:	8556                	mv	a0,s5
    800012f2:	f53ff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    800012f6:	4501                	li	a0,0
    800012f8:	74a2                	ld	s1,40(sp)
    800012fa:	7902                	ld	s2,32(sp)
    800012fc:	6b02                	ld	s6,0(sp)
}
    800012fe:	70e2                	ld	ra,56(sp)
    80001300:	7442                	ld	s0,48(sp)
    80001302:	69e2                	ld	s3,24(sp)
    80001304:	6a42                	ld	s4,16(sp)
    80001306:	6aa2                	ld	s5,8(sp)
    80001308:	6121                	addi	sp,sp,64
    8000130a:	8082                	ret
      kfree(mem);
    8000130c:	8526                	mv	a0,s1
    8000130e:	f0eff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001312:	864e                	mv	a2,s3
    80001314:	85ca                	mv	a1,s2
    80001316:	8556                	mv	a0,s5
    80001318:	f2dff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    8000131c:	4501                	li	a0,0
    8000131e:	74a2                	ld	s1,40(sp)
    80001320:	7902                	ld	s2,32(sp)
    80001322:	6b02                	ld	s6,0(sp)
    80001324:	bfe9                	j	800012fe <uvmalloc+0x76>
    return oldsz;
    80001326:	852e                	mv	a0,a1
}
    80001328:	8082                	ret
  return newsz;
    8000132a:	8532                	mv	a0,a2
    8000132c:	bfc9                	j	800012fe <uvmalloc+0x76>

000000008000132e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000132e:	7179                	addi	sp,sp,-48
    80001330:	f406                	sd	ra,40(sp)
    80001332:	f022                	sd	s0,32(sp)
    80001334:	ec26                	sd	s1,24(sp)
    80001336:	e84a                	sd	s2,16(sp)
    80001338:	e44e                	sd	s3,8(sp)
    8000133a:	e052                	sd	s4,0(sp)
    8000133c:	1800                	addi	s0,sp,48
    8000133e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001340:	84aa                	mv	s1,a0
    80001342:	6905                	lui	s2,0x1
    80001344:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001346:	4985                	li	s3,1
    80001348:	a819                	j	8000135e <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000134a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000134c:	00c79513          	slli	a0,a5,0xc
    80001350:	fdfff0ef          	jal	8000132e <freewalk>
      pagetable[i] = 0;
    80001354:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001358:	04a1                	addi	s1,s1,8
    8000135a:	01248f63          	beq	s1,s2,80001378 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    8000135e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001360:	00f7f713          	andi	a4,a5,15
    80001364:	ff3703e3          	beq	a4,s3,8000134a <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001368:	8b85                	andi	a5,a5,1
    8000136a:	d7fd                	beqz	a5,80001358 <freewalk+0x2a>
      panic("freewalk: leaf");
    8000136c:	00006517          	auipc	a0,0x6
    80001370:	dcc50513          	addi	a0,a0,-564 # 80007138 <etext+0x138>
    80001374:	c6cff0ef          	jal	800007e0 <panic>
    }
  }
  kfree((void*)pagetable);
    80001378:	8552                	mv	a0,s4
    8000137a:	ea2ff0ef          	jal	80000a1c <kfree>
}
    8000137e:	70a2                	ld	ra,40(sp)
    80001380:	7402                	ld	s0,32(sp)
    80001382:	64e2                	ld	s1,24(sp)
    80001384:	6942                	ld	s2,16(sp)
    80001386:	69a2                	ld	s3,8(sp)
    80001388:	6a02                	ld	s4,0(sp)
    8000138a:	6145                	addi	sp,sp,48
    8000138c:	8082                	ret

000000008000138e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000138e:	1101                	addi	sp,sp,-32
    80001390:	ec06                	sd	ra,24(sp)
    80001392:	e822                	sd	s0,16(sp)
    80001394:	e426                	sd	s1,8(sp)
    80001396:	1000                	addi	s0,sp,32
    80001398:	84aa                	mv	s1,a0
  if(sz > 0)
    8000139a:	e989                	bnez	a1,800013ac <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000139c:	8526                	mv	a0,s1
    8000139e:	f91ff0ef          	jal	8000132e <freewalk>
}
    800013a2:	60e2                	ld	ra,24(sp)
    800013a4:	6442                	ld	s0,16(sp)
    800013a6:	64a2                	ld	s1,8(sp)
    800013a8:	6105                	addi	sp,sp,32
    800013aa:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013ac:	6785                	lui	a5,0x1
    800013ae:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013b0:	95be                	add	a1,a1,a5
    800013b2:	4685                	li	a3,1
    800013b4:	00c5d613          	srli	a2,a1,0xc
    800013b8:	4581                	li	a1,0
    800013ba:	e01ff0ef          	jal	800011ba <uvmunmap>
    800013be:	bff9                	j	8000139c <uvmfree+0xe>

00000000800013c0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013c0:	ce49                	beqz	a2,8000145a <uvmcopy+0x9a>
{
    800013c2:	715d                	addi	sp,sp,-80
    800013c4:	e486                	sd	ra,72(sp)
    800013c6:	e0a2                	sd	s0,64(sp)
    800013c8:	fc26                	sd	s1,56(sp)
    800013ca:	f84a                	sd	s2,48(sp)
    800013cc:	f44e                	sd	s3,40(sp)
    800013ce:	f052                	sd	s4,32(sp)
    800013d0:	ec56                	sd	s5,24(sp)
    800013d2:	e85a                	sd	s6,16(sp)
    800013d4:	e45e                	sd	s7,8(sp)
    800013d6:	0880                	addi	s0,sp,80
    800013d8:	8aaa                	mv	s5,a0
    800013da:	8b2e                	mv	s6,a1
    800013dc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800013de:	4481                	li	s1,0
    800013e0:	a029                	j	800013ea <uvmcopy+0x2a>
    800013e2:	6785                	lui	a5,0x1
    800013e4:	94be                	add	s1,s1,a5
    800013e6:	0544fe63          	bgeu	s1,s4,80001442 <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    800013ea:	4601                	li	a2,0
    800013ec:	85a6                	mv	a1,s1
    800013ee:	8556                	mv	a0,s5
    800013f0:	b27ff0ef          	jal	80000f16 <walk>
    800013f4:	d57d                	beqz	a0,800013e2 <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    800013f6:	6118                	ld	a4,0(a0)
    800013f8:	00177793          	andi	a5,a4,1
    800013fc:	d3fd                	beqz	a5,800013e2 <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    800013fe:	00a75593          	srli	a1,a4,0xa
    80001402:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001406:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000140a:	ef4ff0ef          	jal	80000afe <kalloc>
    8000140e:	89aa                	mv	s3,a0
    80001410:	c105                	beqz	a0,80001430 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001412:	6605                	lui	a2,0x1
    80001414:	85de                	mv	a1,s7
    80001416:	8e9ff0ef          	jal	80000cfe <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000141a:	874a                	mv	a4,s2
    8000141c:	86ce                	mv	a3,s3
    8000141e:	6605                	lui	a2,0x1
    80001420:	85a6                	mv	a1,s1
    80001422:	855a                	mv	a0,s6
    80001424:	bcbff0ef          	jal	80000fee <mappages>
    80001428:	dd4d                	beqz	a0,800013e2 <uvmcopy+0x22>
      kfree(mem);
    8000142a:	854e                	mv	a0,s3
    8000142c:	df0ff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001430:	4685                	li	a3,1
    80001432:	00c4d613          	srli	a2,s1,0xc
    80001436:	4581                	li	a1,0
    80001438:	855a                	mv	a0,s6
    8000143a:	d81ff0ef          	jal	800011ba <uvmunmap>
  return -1;
    8000143e:	557d                	li	a0,-1
    80001440:	a011                	j	80001444 <uvmcopy+0x84>
  return 0;
    80001442:	4501                	li	a0,0
}
    80001444:	60a6                	ld	ra,72(sp)
    80001446:	6406                	ld	s0,64(sp)
    80001448:	74e2                	ld	s1,56(sp)
    8000144a:	7942                	ld	s2,48(sp)
    8000144c:	79a2                	ld	s3,40(sp)
    8000144e:	7a02                	ld	s4,32(sp)
    80001450:	6ae2                	ld	s5,24(sp)
    80001452:	6b42                	ld	s6,16(sp)
    80001454:	6ba2                	ld	s7,8(sp)
    80001456:	6161                	addi	sp,sp,80
    80001458:	8082                	ret
  return 0;
    8000145a:	4501                	li	a0,0
}
    8000145c:	8082                	ret

000000008000145e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000145e:	1141                	addi	sp,sp,-16
    80001460:	e406                	sd	ra,8(sp)
    80001462:	e022                	sd	s0,0(sp)
    80001464:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001466:	4601                	li	a2,0
    80001468:	aafff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    8000146c:	c901                	beqz	a0,8000147c <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000146e:	611c                	ld	a5,0(a0)
    80001470:	9bbd                	andi	a5,a5,-17
    80001472:	e11c                	sd	a5,0(a0)
}
    80001474:	60a2                	ld	ra,8(sp)
    80001476:	6402                	ld	s0,0(sp)
    80001478:	0141                	addi	sp,sp,16
    8000147a:	8082                	ret
    panic("uvmclear");
    8000147c:	00006517          	auipc	a0,0x6
    80001480:	ccc50513          	addi	a0,a0,-820 # 80007148 <etext+0x148>
    80001484:	b5cff0ef          	jal	800007e0 <panic>

0000000080001488 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001488:	c6dd                	beqz	a3,80001536 <copyinstr+0xae>
{
    8000148a:	715d                	addi	sp,sp,-80
    8000148c:	e486                	sd	ra,72(sp)
    8000148e:	e0a2                	sd	s0,64(sp)
    80001490:	fc26                	sd	s1,56(sp)
    80001492:	f84a                	sd	s2,48(sp)
    80001494:	f44e                	sd	s3,40(sp)
    80001496:	f052                	sd	s4,32(sp)
    80001498:	ec56                	sd	s5,24(sp)
    8000149a:	e85a                	sd	s6,16(sp)
    8000149c:	e45e                	sd	s7,8(sp)
    8000149e:	0880                	addi	s0,sp,80
    800014a0:	8a2a                	mv	s4,a0
    800014a2:	8b2e                	mv	s6,a1
    800014a4:	8bb2                	mv	s7,a2
    800014a6:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014a8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014aa:	6985                	lui	s3,0x1
    800014ac:	a825                	j	800014e4 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014ae:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014b4:	37fd                	addiw	a5,a5,-1
    800014b6:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014ba:	60a6                	ld	ra,72(sp)
    800014bc:	6406                	ld	s0,64(sp)
    800014be:	74e2                	ld	s1,56(sp)
    800014c0:	7942                	ld	s2,48(sp)
    800014c2:	79a2                	ld	s3,40(sp)
    800014c4:	7a02                	ld	s4,32(sp)
    800014c6:	6ae2                	ld	s5,24(sp)
    800014c8:	6b42                	ld	s6,16(sp)
    800014ca:	6ba2                	ld	s7,8(sp)
    800014cc:	6161                	addi	sp,sp,80
    800014ce:	8082                	ret
    800014d0:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    800014d4:	9742                	add	a4,a4,a6
      --max;
    800014d6:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    800014da:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    800014de:	04e58463          	beq	a1,a4,80001526 <copyinstr+0x9e>
{
    800014e2:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    800014e4:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800014e8:	85a6                	mv	a1,s1
    800014ea:	8552                	mv	a0,s4
    800014ec:	ac5ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0)
    800014f0:	cd0d                	beqz	a0,8000152a <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800014f2:	417486b3          	sub	a3,s1,s7
    800014f6:	96ce                	add	a3,a3,s3
    if(n > max)
    800014f8:	00d97363          	bgeu	s2,a3,800014fe <copyinstr+0x76>
    800014fc:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    800014fe:	955e                	add	a0,a0,s7
    80001500:	8d05                	sub	a0,a0,s1
    while(n > 0){
    80001502:	c695                	beqz	a3,8000152e <copyinstr+0xa6>
    80001504:	87da                	mv	a5,s6
    80001506:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001508:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000150c:	96da                	add	a3,a3,s6
    8000150e:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001510:	00f60733          	add	a4,a2,a5
    80001514:	00074703          	lbu	a4,0(a4)
    80001518:	db59                	beqz	a4,800014ae <copyinstr+0x26>
        *dst = *p;
    8000151a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000151e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001520:	fed797e3          	bne	a5,a3,8000150e <copyinstr+0x86>
    80001524:	b775                	j	800014d0 <copyinstr+0x48>
    80001526:	4781                	li	a5,0
    80001528:	b771                	j	800014b4 <copyinstr+0x2c>
      return -1;
    8000152a:	557d                	li	a0,-1
    8000152c:	b779                	j	800014ba <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    8000152e:	6b85                	lui	s7,0x1
    80001530:	9ba6                	add	s7,s7,s1
    80001532:	87da                	mv	a5,s6
    80001534:	b77d                	j	800014e2 <copyinstr+0x5a>
  int got_null = 0;
    80001536:	4781                	li	a5,0
  if(got_null){
    80001538:	37fd                	addiw	a5,a5,-1
    8000153a:	0007851b          	sext.w	a0,a5
}
    8000153e:	8082                	ret

0000000080001540 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001540:	1141                	addi	sp,sp,-16
    80001542:	e406                	sd	ra,8(sp)
    80001544:	e022                	sd	s0,0(sp)
    80001546:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001548:	4601                	li	a2,0
    8000154a:	9cdff0ef          	jal	80000f16 <walk>
  if (pte == 0) {
    8000154e:	c519                	beqz	a0,8000155c <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001550:	6108                	ld	a0,0(a0)
    80001552:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80001554:	60a2                	ld	ra,8(sp)
    80001556:	6402                	ld	s0,0(sp)
    80001558:	0141                	addi	sp,sp,16
    8000155a:	8082                	ret
    return 0;
    8000155c:	4501                	li	a0,0
    8000155e:	bfdd                	j	80001554 <ismapped+0x14>

0000000080001560 <vmfault>:
{
    80001560:	7179                	addi	sp,sp,-48
    80001562:	f406                	sd	ra,40(sp)
    80001564:	f022                	sd	s0,32(sp)
    80001566:	ec26                	sd	s1,24(sp)
    80001568:	e44e                	sd	s3,8(sp)
    8000156a:	1800                	addi	s0,sp,48
    8000156c:	89aa                	mv	s3,a0
    8000156e:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80001570:	35e000ef          	jal	800018ce <myproc>
  if (va >= p->sz)
    80001574:	713c                	ld	a5,96(a0)
    80001576:	00f4ea63          	bltu	s1,a5,8000158a <vmfault+0x2a>
    return 0;
    8000157a:	4981                	li	s3,0
}
    8000157c:	854e                	mv	a0,s3
    8000157e:	70a2                	ld	ra,40(sp)
    80001580:	7402                	ld	s0,32(sp)
    80001582:	64e2                	ld	s1,24(sp)
    80001584:	69a2                	ld	s3,8(sp)
    80001586:	6145                	addi	sp,sp,48
    80001588:	8082                	ret
    8000158a:	e84a                	sd	s2,16(sp)
    8000158c:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    8000158e:	77fd                	lui	a5,0xfffff
    80001590:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    80001592:	85a6                	mv	a1,s1
    80001594:	854e                	mv	a0,s3
    80001596:	fabff0ef          	jal	80001540 <ismapped>
    return 0;
    8000159a:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    8000159c:	c119                	beqz	a0,800015a2 <vmfault+0x42>
    8000159e:	6942                	ld	s2,16(sp)
    800015a0:	bff1                	j	8000157c <vmfault+0x1c>
    800015a2:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015a4:	d5aff0ef          	jal	80000afe <kalloc>
    800015a8:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015aa:	c90d                	beqz	a0,800015dc <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015ac:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	4581                	li	a1,0
    800015b2:	ef0ff0ef          	jal	80000ca2 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015b6:	4759                	li	a4,22
    800015b8:	86d2                	mv	a3,s4
    800015ba:	6605                	lui	a2,0x1
    800015bc:	85a6                	mv	a1,s1
    800015be:	06893503          	ld	a0,104(s2)
    800015c2:	a2dff0ef          	jal	80000fee <mappages>
    800015c6:	e501                	bnez	a0,800015ce <vmfault+0x6e>
    800015c8:	6942                	ld	s2,16(sp)
    800015ca:	6a02                	ld	s4,0(sp)
    800015cc:	bf45                	j	8000157c <vmfault+0x1c>
    kfree((void *)mem);
    800015ce:	8552                	mv	a0,s4
    800015d0:	c4cff0ef          	jal	80000a1c <kfree>
    return 0;
    800015d4:	4981                	li	s3,0
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	6a02                	ld	s4,0(sp)
    800015da:	b74d                	j	8000157c <vmfault+0x1c>
    800015dc:	6942                	ld	s2,16(sp)
    800015de:	6a02                	ld	s4,0(sp)
    800015e0:	bf71                	j	8000157c <vmfault+0x1c>

00000000800015e2 <copyout>:
  while(len > 0){
    800015e2:	c2cd                	beqz	a3,80001684 <copyout+0xa2>
{
    800015e4:	711d                	addi	sp,sp,-96
    800015e6:	ec86                	sd	ra,88(sp)
    800015e8:	e8a2                	sd	s0,80(sp)
    800015ea:	e4a6                	sd	s1,72(sp)
    800015ec:	f852                	sd	s4,48(sp)
    800015ee:	f05a                	sd	s6,32(sp)
    800015f0:	ec5e                	sd	s7,24(sp)
    800015f2:	e862                	sd	s8,16(sp)
    800015f4:	1080                	addi	s0,sp,96
    800015f6:	8c2a                	mv	s8,a0
    800015f8:	8b2e                	mv	s6,a1
    800015fa:	8bb2                	mv	s7,a2
    800015fc:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800015fe:	74fd                	lui	s1,0xfffff
    80001600:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001602:	57fd                	li	a5,-1
    80001604:	83e9                	srli	a5,a5,0x1a
    80001606:	0897e163          	bltu	a5,s1,80001688 <copyout+0xa6>
    8000160a:	e0ca                	sd	s2,64(sp)
    8000160c:	fc4e                	sd	s3,56(sp)
    8000160e:	f456                	sd	s5,40(sp)
    80001610:	e466                	sd	s9,8(sp)
    80001612:	e06a                	sd	s10,0(sp)
    80001614:	6d05                	lui	s10,0x1
    80001616:	8cbe                	mv	s9,a5
    80001618:	a015                	j	8000163c <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000161a:	409b0533          	sub	a0,s6,s1
    8000161e:	0009861b          	sext.w	a2,s3
    80001622:	85de                	mv	a1,s7
    80001624:	954a                	add	a0,a0,s2
    80001626:	ed8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000162a:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000162e:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001630:	040a0363          	beqz	s4,80001676 <copyout+0x94>
    if(va0 >= MAXVA)
    80001634:	055cec63          	bltu	s9,s5,8000168c <copyout+0xaa>
    80001638:	84d6                	mv	s1,s5
    8000163a:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    8000163c:	85a6                	mv	a1,s1
    8000163e:	8562                	mv	a0,s8
    80001640:	971ff0ef          	jal	80000fb0 <walkaddr>
    80001644:	892a                	mv	s2,a0
    if(pa0 == 0) {
    80001646:	e901                	bnez	a0,80001656 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001648:	4601                	li	a2,0
    8000164a:	85a6                	mv	a1,s1
    8000164c:	8562                	mv	a0,s8
    8000164e:	f13ff0ef          	jal	80001560 <vmfault>
    80001652:	892a                	mv	s2,a0
    80001654:	c139                	beqz	a0,8000169a <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    80001656:	4601                	li	a2,0
    80001658:	85a6                	mv	a1,s1
    8000165a:	8562                	mv	a0,s8
    8000165c:	8bbff0ef          	jal	80000f16 <walk>
    if((*pte & PTE_W) == 0)
    80001660:	611c                	ld	a5,0(a0)
    80001662:	8b91                	andi	a5,a5,4
    80001664:	c3b1                	beqz	a5,800016a8 <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    80001666:	01a48ab3          	add	s5,s1,s10
    8000166a:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    8000166e:	fb3a76e3          	bgeu	s4,s3,8000161a <copyout+0x38>
    80001672:	89d2                	mv	s3,s4
    80001674:	b75d                	j	8000161a <copyout+0x38>
  return 0;
    80001676:	4501                	li	a0,0
    80001678:	6906                	ld	s2,64(sp)
    8000167a:	79e2                	ld	s3,56(sp)
    8000167c:	7aa2                	ld	s5,40(sp)
    8000167e:	6ca2                	ld	s9,8(sp)
    80001680:	6d02                	ld	s10,0(sp)
    80001682:	a80d                	j	800016b4 <copyout+0xd2>
    80001684:	4501                	li	a0,0
}
    80001686:	8082                	ret
      return -1;
    80001688:	557d                	li	a0,-1
    8000168a:	a02d                	j	800016b4 <copyout+0xd2>
    8000168c:	557d                	li	a0,-1
    8000168e:	6906                	ld	s2,64(sp)
    80001690:	79e2                	ld	s3,56(sp)
    80001692:	7aa2                	ld	s5,40(sp)
    80001694:	6ca2                	ld	s9,8(sp)
    80001696:	6d02                	ld	s10,0(sp)
    80001698:	a831                	j	800016b4 <copyout+0xd2>
        return -1;
    8000169a:	557d                	li	a0,-1
    8000169c:	6906                	ld	s2,64(sp)
    8000169e:	79e2                	ld	s3,56(sp)
    800016a0:	7aa2                	ld	s5,40(sp)
    800016a2:	6ca2                	ld	s9,8(sp)
    800016a4:	6d02                	ld	s10,0(sp)
    800016a6:	a039                	j	800016b4 <copyout+0xd2>
      return -1;
    800016a8:	557d                	li	a0,-1
    800016aa:	6906                	ld	s2,64(sp)
    800016ac:	79e2                	ld	s3,56(sp)
    800016ae:	7aa2                	ld	s5,40(sp)
    800016b0:	6ca2                	ld	s9,8(sp)
    800016b2:	6d02                	ld	s10,0(sp)
}
    800016b4:	60e6                	ld	ra,88(sp)
    800016b6:	6446                	ld	s0,80(sp)
    800016b8:	64a6                	ld	s1,72(sp)
    800016ba:	7a42                	ld	s4,48(sp)
    800016bc:	7b02                	ld	s6,32(sp)
    800016be:	6be2                	ld	s7,24(sp)
    800016c0:	6c42                	ld	s8,16(sp)
    800016c2:	6125                	addi	sp,sp,96
    800016c4:	8082                	ret

00000000800016c6 <copyin>:
  while(len > 0){
    800016c6:	c6c9                	beqz	a3,80001750 <copyin+0x8a>
{
    800016c8:	715d                	addi	sp,sp,-80
    800016ca:	e486                	sd	ra,72(sp)
    800016cc:	e0a2                	sd	s0,64(sp)
    800016ce:	fc26                	sd	s1,56(sp)
    800016d0:	f84a                	sd	s2,48(sp)
    800016d2:	f44e                	sd	s3,40(sp)
    800016d4:	f052                	sd	s4,32(sp)
    800016d6:	ec56                	sd	s5,24(sp)
    800016d8:	e85a                	sd	s6,16(sp)
    800016da:	e45e                	sd	s7,8(sp)
    800016dc:	e062                	sd	s8,0(sp)
    800016de:	0880                	addi	s0,sp,80
    800016e0:	8baa                	mv	s7,a0
    800016e2:	8aae                	mv	s5,a1
    800016e4:	8932                	mv	s2,a2
    800016e6:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    800016e8:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    800016ea:	6b05                	lui	s6,0x1
    800016ec:	a035                	j	80001718 <copyin+0x52>
    800016ee:	412984b3          	sub	s1,s3,s2
    800016f2:	94da                	add	s1,s1,s6
    if(n > len)
    800016f4:	009a7363          	bgeu	s4,s1,800016fa <copyin+0x34>
    800016f8:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016fa:	413905b3          	sub	a1,s2,s3
    800016fe:	0004861b          	sext.w	a2,s1
    80001702:	95aa                	add	a1,a1,a0
    80001704:	8556                	mv	a0,s5
    80001706:	df8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000170a:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000170e:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001710:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001714:	020a0163          	beqz	s4,80001736 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001718:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000171c:	85ce                	mv	a1,s3
    8000171e:	855e                	mv	a0,s7
    80001720:	891ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0) {
    80001724:	f569                	bnez	a0,800016ee <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001726:	4601                	li	a2,0
    80001728:	85ce                	mv	a1,s3
    8000172a:	855e                	mv	a0,s7
    8000172c:	e35ff0ef          	jal	80001560 <vmfault>
    80001730:	fd5d                	bnez	a0,800016ee <copyin+0x28>
        return -1;
    80001732:	557d                	li	a0,-1
    80001734:	a011                	j	80001738 <copyin+0x72>
  return 0;
    80001736:	4501                	li	a0,0
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6c02                	ld	s8,0(sp)
    8000174c:	6161                	addi	sp,sp,80
    8000174e:	8082                	ret
  return 0;
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret

0000000080001754 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001754:	7139                	addi	sp,sp,-64
    80001756:	fc06                	sd	ra,56(sp)
    80001758:	f822                	sd	s0,48(sp)
    8000175a:	f426                	sd	s1,40(sp)
    8000175c:	f04a                	sd	s2,32(sp)
    8000175e:	ec4e                	sd	s3,24(sp)
    80001760:	e852                	sd	s4,16(sp)
    80001762:	e456                	sd	s5,8(sp)
    80001764:	e05a                	sd	s6,0(sp)
    80001766:	0080                	addi	s0,sp,64
    80001768:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000176a:	0000e497          	auipc	s1,0xe
    8000176e:	68e48493          	addi	s1,s1,1678 # 8000fdf8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001772:	8b26                	mv	s6,s1
    80001774:	faaab937          	lui	s2,0xfaaab
    80001778:	aab90913          	addi	s2,s2,-1365 # fffffffffaaaaaab <end+0xffffffff7aa898d3>
    8000177c:	0932                	slli	s2,s2,0xc
    8000177e:	aab90913          	addi	s2,s2,-1365
    80001782:	0932                	slli	s2,s2,0xc
    80001784:	aab90913          	addi	s2,s2,-1365
    80001788:	0932                	slli	s2,s2,0xc
    8000178a:	aab90913          	addi	s2,s2,-1365
    8000178e:	040009b7          	lui	s3,0x4000
    80001792:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001794:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001796:	00014a97          	auipc	s5,0x14
    8000179a:	662a8a93          	addi	s5,s5,1634 # 80015df8 <tickslock>
    char *pa = kalloc();
    8000179e:	b60ff0ef          	jal	80000afe <kalloc>
    800017a2:	862a                	mv	a2,a0
    if(pa == 0)
    800017a4:	cd15                	beqz	a0,800017e0 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int) (p - proc));
    800017a6:	416485b3          	sub	a1,s1,s6
    800017aa:	859d                	srai	a1,a1,0x7
    800017ac:	032585b3          	mul	a1,a1,s2
    800017b0:	2585                	addiw	a1,a1,1
    800017b2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017b6:	4719                	li	a4,6
    800017b8:	6685                	lui	a3,0x1
    800017ba:	40b985b3          	sub	a1,s3,a1
    800017be:	8552                	mv	a0,s4
    800017c0:	8dfff0ef          	jal	8000109e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017c4:	18048493          	addi	s1,s1,384
    800017c8:	fd549be3          	bne	s1,s5,8000179e <proc_mapstacks+0x4a>
  }
}
    800017cc:	70e2                	ld	ra,56(sp)
    800017ce:	7442                	ld	s0,48(sp)
    800017d0:	74a2                	ld	s1,40(sp)
    800017d2:	7902                	ld	s2,32(sp)
    800017d4:	69e2                	ld	s3,24(sp)
    800017d6:	6a42                	ld	s4,16(sp)
    800017d8:	6aa2                	ld	s5,8(sp)
    800017da:	6b02                	ld	s6,0(sp)
    800017dc:	6121                	addi	sp,sp,64
    800017de:	8082                	ret
      panic("kalloc");
    800017e0:	00006517          	auipc	a0,0x6
    800017e4:	97850513          	addi	a0,a0,-1672 # 80007158 <etext+0x158>
    800017e8:	ff9fe0ef          	jal	800007e0 <panic>

00000000800017ec <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800017ec:	7139                	addi	sp,sp,-64
    800017ee:	fc06                	sd	ra,56(sp)
    800017f0:	f822                	sd	s0,48(sp)
    800017f2:	f426                	sd	s1,40(sp)
    800017f4:	f04a                	sd	s2,32(sp)
    800017f6:	ec4e                	sd	s3,24(sp)
    800017f8:	e852                	sd	s4,16(sp)
    800017fa:	e456                	sd	s5,8(sp)
    800017fc:	e05a                	sd	s6,0(sp)
    800017fe:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001800:	00006597          	auipc	a1,0x6
    80001804:	96058593          	addi	a1,a1,-1696 # 80007160 <etext+0x160>
    80001808:	0000e517          	auipc	a0,0xe
    8000180c:	1c050513          	addi	a0,a0,448 # 8000f9c8 <pid_lock>
    80001810:	b3eff0ef          	jal	80000b4e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001814:	00006597          	auipc	a1,0x6
    80001818:	95458593          	addi	a1,a1,-1708 # 80007168 <etext+0x168>
    8000181c:	0000e517          	auipc	a0,0xe
    80001820:	1c450513          	addi	a0,a0,452 # 8000f9e0 <wait_lock>
    80001824:	b2aff0ef          	jal	80000b4e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001828:	0000e497          	auipc	s1,0xe
    8000182c:	5d048493          	addi	s1,s1,1488 # 8000fdf8 <proc>
      initlock(&p->lock, "proc");
    80001830:	00006b17          	auipc	s6,0x6
    80001834:	948b0b13          	addi	s6,s6,-1720 # 80007178 <etext+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001838:	8aa6                	mv	s5,s1
    8000183a:	faaab937          	lui	s2,0xfaaab
    8000183e:	aab90913          	addi	s2,s2,-1365 # fffffffffaaaaaab <end+0xffffffff7aa898d3>
    80001842:	0932                	slli	s2,s2,0xc
    80001844:	aab90913          	addi	s2,s2,-1365
    80001848:	0932                	slli	s2,s2,0xc
    8000184a:	aab90913          	addi	s2,s2,-1365
    8000184e:	0932                	slli	s2,s2,0xc
    80001850:	aab90913          	addi	s2,s2,-1365
    80001854:	040009b7          	lui	s3,0x4000
    80001858:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000185a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00014a17          	auipc	s4,0x14
    80001860:	59ca0a13          	addi	s4,s4,1436 # 80015df8 <tickslock>
      initlock(&p->lock, "proc");
    80001864:	85da                	mv	a1,s6
    80001866:	8526                	mv	a0,s1
    80001868:	ae6ff0ef          	jal	80000b4e <initlock>
      p->state = UNUSED;
    8000186c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001870:	415487b3          	sub	a5,s1,s5
    80001874:	879d                	srai	a5,a5,0x7
    80001876:	032787b3          	mul	a5,a5,s2
    8000187a:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffdde29>
    8000187c:	00d7979b          	slliw	a5,a5,0xd
    80001880:	40f987b3          	sub	a5,s3,a5
    80001884:	ecbc                	sd	a5,88(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001886:	18048493          	addi	s1,s1,384
    8000188a:	fd449de3          	bne	s1,s4,80001864 <procinit+0x78>
  }
}
    8000188e:	70e2                	ld	ra,56(sp)
    80001890:	7442                	ld	s0,48(sp)
    80001892:	74a2                	ld	s1,40(sp)
    80001894:	7902                	ld	s2,32(sp)
    80001896:	69e2                	ld	s3,24(sp)
    80001898:	6a42                	ld	s4,16(sp)
    8000189a:	6aa2                	ld	s5,8(sp)
    8000189c:	6b02                	ld	s6,0(sp)
    8000189e:	6121                	addi	sp,sp,64
    800018a0:	8082                	ret

00000000800018a2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018a2:	1141                	addi	sp,sp,-16
    800018a4:	e422                	sd	s0,8(sp)
    800018a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018a8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018aa:	2501                	sext.w	a0,a0
    800018ac:	6422                	ld	s0,8(sp)
    800018ae:	0141                	addi	sp,sp,16
    800018b0:	8082                	ret

00000000800018b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018b2:	1141                	addi	sp,sp,-16
    800018b4:	e422                	sd	s0,8(sp)
    800018b6:	0800                	addi	s0,sp,16
    800018b8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018ba:	2781                	sext.w	a5,a5
    800018bc:	079e                	slli	a5,a5,0x7
  return c;
}
    800018be:	0000e517          	auipc	a0,0xe
    800018c2:	13a50513          	addi	a0,a0,314 # 8000f9f8 <cpus>
    800018c6:	953e                	add	a0,a0,a5
    800018c8:	6422                	ld	s0,8(sp)
    800018ca:	0141                	addi	sp,sp,16
    800018cc:	8082                	ret

00000000800018ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800018ce:	1101                	addi	sp,sp,-32
    800018d0:	ec06                	sd	ra,24(sp)
    800018d2:	e822                	sd	s0,16(sp)
    800018d4:	e426                	sd	s1,8(sp)
    800018d6:	1000                	addi	s0,sp,32
  push_off();
    800018d8:	ab6ff0ef          	jal	80000b8e <push_off>
    800018dc:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800018de:	2781                	sext.w	a5,a5
    800018e0:	079e                	slli	a5,a5,0x7
    800018e2:	0000e717          	auipc	a4,0xe
    800018e6:	0e670713          	addi	a4,a4,230 # 8000f9c8 <pid_lock>
    800018ea:	97ba                	add	a5,a5,a4
    800018ec:	7b84                	ld	s1,48(a5)
  pop_off();
    800018ee:	b24ff0ef          	jal	80000c12 <pop_off>
  return p;
}
    800018f2:	8526                	mv	a0,s1
    800018f4:	60e2                	ld	ra,24(sp)
    800018f6:	6442                	ld	s0,16(sp)
    800018f8:	64a2                	ld	s1,8(sp)
    800018fa:	6105                	addi	sp,sp,32
    800018fc:	8082                	ret

00000000800018fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800018fe:	7179                	addi	sp,sp,-48
    80001900:	f406                	sd	ra,40(sp)
    80001902:	f022                	sd	s0,32(sp)
    80001904:	ec26                	sd	s1,24(sp)
    80001906:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001908:	fc7ff0ef          	jal	800018ce <myproc>
    8000190c:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    8000190e:	b58ff0ef          	jal	80000c66 <release>

  if (first) {
    80001912:	00006797          	auipc	a5,0x6
    80001916:	f7e7a783          	lw	a5,-130(a5) # 80007890 <first.1>
    8000191a:	cf8d                	beqz	a5,80001954 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    8000191c:	4505                	li	a0,1
    8000191e:	4a5010ef          	jal	800035c2 <fsinit>

    first = 0;
    80001922:	00006797          	auipc	a5,0x6
    80001926:	f607a723          	sw	zero,-146(a5) # 80007890 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    8000192a:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    8000192e:	00006517          	auipc	a0,0x6
    80001932:	85250513          	addi	a0,a0,-1966 # 80007180 <etext+0x180>
    80001936:	fca43823          	sd	a0,-48(s0)
    8000193a:	fc043c23          	sd	zero,-40(s0)
    8000193e:	fd040593          	addi	a1,s0,-48
    80001942:	581020ef          	jal	800046c2 <kexec>
    80001946:	78bc                	ld	a5,112(s1)
    80001948:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    8000194a:	78bc                	ld	a5,112(s1)
    8000194c:	7bb8                	ld	a4,112(a5)
    8000194e:	57fd                	li	a5,-1
    80001950:	02f70d63          	beq	a4,a5,8000198a <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001954:	375000ef          	jal	800024c8 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001958:	74a8                	ld	a0,104(s1)
    8000195a:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000195c:	04000737          	lui	a4,0x4000
    80001960:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80001962:	0732                	slli	a4,a4,0xc
    80001964:	00004797          	auipc	a5,0x4
    80001968:	73878793          	addi	a5,a5,1848 # 8000609c <userret>
    8000196c:	00004697          	auipc	a3,0x4
    80001970:	69468693          	addi	a3,a3,1684 # 80006000 <_trampoline>
    80001974:	8f95                	sub	a5,a5,a3
    80001976:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001978:	577d                	li	a4,-1
    8000197a:	177e                	slli	a4,a4,0x3f
    8000197c:	8d59                	or	a0,a0,a4
    8000197e:	9782                	jalr	a5
}
    80001980:	70a2                	ld	ra,40(sp)
    80001982:	7402                	ld	s0,32(sp)
    80001984:	64e2                	ld	s1,24(sp)
    80001986:	6145                	addi	sp,sp,48
    80001988:	8082                	ret
      panic("exec");
    8000198a:	00005517          	auipc	a0,0x5
    8000198e:	7fe50513          	addi	a0,a0,2046 # 80007188 <etext+0x188>
    80001992:	e4ffe0ef          	jal	800007e0 <panic>

0000000080001996 <allocpid>:
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	e04a                	sd	s2,0(sp)
    800019a0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019a2:	0000e917          	auipc	s2,0xe
    800019a6:	02690913          	addi	s2,s2,38 # 8000f9c8 <pid_lock>
    800019aa:	854a                	mv	a0,s2
    800019ac:	a22ff0ef          	jal	80000bce <acquire>
  pid = nextpid;
    800019b0:	00006797          	auipc	a5,0x6
    800019b4:	ee478793          	addi	a5,a5,-284 # 80007894 <nextpid>
    800019b8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019ba:	0014871b          	addiw	a4,s1,1
    800019be:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019c0:	854a                	mv	a0,s2
    800019c2:	aa4ff0ef          	jal	80000c66 <release>
}
    800019c6:	8526                	mv	a0,s1
    800019c8:	60e2                	ld	ra,24(sp)
    800019ca:	6442                	ld	s0,16(sp)
    800019cc:	64a2                	ld	s1,8(sp)
    800019ce:	6902                	ld	s2,0(sp)
    800019d0:	6105                	addi	sp,sp,32
    800019d2:	8082                	ret

00000000800019d4 <proc_pagetable>:
{
    800019d4:	1101                	addi	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	e04a                	sd	s2,0(sp)
    800019de:	1000                	addi	s0,sp,32
    800019e0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019e2:	fb2ff0ef          	jal	80001194 <uvmcreate>
    800019e6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019e8:	cd05                	beqz	a0,80001a20 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019ea:	4729                	li	a4,10
    800019ec:	00004697          	auipc	a3,0x4
    800019f0:	61468693          	addi	a3,a3,1556 # 80006000 <_trampoline>
    800019f4:	6605                	lui	a2,0x1
    800019f6:	040005b7          	lui	a1,0x4000
    800019fa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800019fc:	05b2                	slli	a1,a1,0xc
    800019fe:	df0ff0ef          	jal	80000fee <mappages>
    80001a02:	02054663          	bltz	a0,80001a2e <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a06:	4719                	li	a4,6
    80001a08:	07093683          	ld	a3,112(s2)
    80001a0c:	6605                	lui	a2,0x1
    80001a0e:	020005b7          	lui	a1,0x2000
    80001a12:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a14:	05b6                	slli	a1,a1,0xd
    80001a16:	8526                	mv	a0,s1
    80001a18:	dd6ff0ef          	jal	80000fee <mappages>
    80001a1c:	00054f63          	bltz	a0,80001a3a <proc_pagetable+0x66>
}
    80001a20:	8526                	mv	a0,s1
    80001a22:	60e2                	ld	ra,24(sp)
    80001a24:	6442                	ld	s0,16(sp)
    80001a26:	64a2                	ld	s1,8(sp)
    80001a28:	6902                	ld	s2,0(sp)
    80001a2a:	6105                	addi	sp,sp,32
    80001a2c:	8082                	ret
    uvmfree(pagetable, 0);
    80001a2e:	4581                	li	a1,0
    80001a30:	8526                	mv	a0,s1
    80001a32:	95dff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001a36:	4481                	li	s1,0
    80001a38:	b7e5                	j	80001a20 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a3a:	4681                	li	a3,0
    80001a3c:	4605                	li	a2,1
    80001a3e:	040005b7          	lui	a1,0x4000
    80001a42:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a44:	05b2                	slli	a1,a1,0xc
    80001a46:	8526                	mv	a0,s1
    80001a48:	f72ff0ef          	jal	800011ba <uvmunmap>
    uvmfree(pagetable, 0);
    80001a4c:	4581                	li	a1,0
    80001a4e:	8526                	mv	a0,s1
    80001a50:	93fff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001a54:	4481                	li	s1,0
    80001a56:	b7e9                	j	80001a20 <proc_pagetable+0x4c>

0000000080001a58 <proc_freepagetable>:
{
    80001a58:	1101                	addi	sp,sp,-32
    80001a5a:	ec06                	sd	ra,24(sp)
    80001a5c:	e822                	sd	s0,16(sp)
    80001a5e:	e426                	sd	s1,8(sp)
    80001a60:	e04a                	sd	s2,0(sp)
    80001a62:	1000                	addi	s0,sp,32
    80001a64:	84aa                	mv	s1,a0
    80001a66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a68:	4681                	li	a3,0
    80001a6a:	4605                	li	a2,1
    80001a6c:	040005b7          	lui	a1,0x4000
    80001a70:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a72:	05b2                	slli	a1,a1,0xc
    80001a74:	f46ff0ef          	jal	800011ba <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a78:	4681                	li	a3,0
    80001a7a:	4605                	li	a2,1
    80001a7c:	020005b7          	lui	a1,0x2000
    80001a80:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a82:	05b6                	slli	a1,a1,0xd
    80001a84:	8526                	mv	a0,s1
    80001a86:	f34ff0ef          	jal	800011ba <uvmunmap>
  uvmfree(pagetable, sz);
    80001a8a:	85ca                	mv	a1,s2
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	901ff0ef          	jal	8000138e <uvmfree>
}
    80001a92:	60e2                	ld	ra,24(sp)
    80001a94:	6442                	ld	s0,16(sp)
    80001a96:	64a2                	ld	s1,8(sp)
    80001a98:	6902                	ld	s2,0(sp)
    80001a9a:	6105                	addi	sp,sp,32
    80001a9c:	8082                	ret

0000000080001a9e <freeproc>:
{
    80001a9e:	1101                	addi	sp,sp,-32
    80001aa0:	ec06                	sd	ra,24(sp)
    80001aa2:	e822                	sd	s0,16(sp)
    80001aa4:	e426                	sd	s1,8(sp)
    80001aa6:	1000                	addi	s0,sp,32
    80001aa8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001aaa:	7928                	ld	a0,112(a0)
    80001aac:	c119                	beqz	a0,80001ab2 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001aae:	f6ffe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80001ab2:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80001ab6:	74a8                	ld	a0,104(s1)
    80001ab8:	c501                	beqz	a0,80001ac0 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001aba:	70ac                	ld	a1,96(s1)
    80001abc:	f9dff0ef          	jal	80001a58 <proc_freepagetable>
  p->pagetable = 0;
    80001ac0:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001ac4:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001ac8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001acc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ad0:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001ad4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ad8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001adc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ae0:	0004ac23          	sw	zero,24(s1)
}
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6105                	addi	sp,sp,32
    80001aec:	8082                	ret

0000000080001aee <allocproc>:
{
    80001aee:	1101                	addi	sp,sp,-32
    80001af0:	ec06                	sd	ra,24(sp)
    80001af2:	e822                	sd	s0,16(sp)
    80001af4:	e426                	sd	s1,8(sp)
    80001af6:	e04a                	sd	s2,0(sp)
    80001af8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001afa:	0000e497          	auipc	s1,0xe
    80001afe:	2fe48493          	addi	s1,s1,766 # 8000fdf8 <proc>
    80001b02:	00014917          	auipc	s2,0x14
    80001b06:	2f690913          	addi	s2,s2,758 # 80015df8 <tickslock>
    acquire(&p->lock);
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	8c2ff0ef          	jal	80000bce <acquire>
    if(p->state == UNUSED) {
    80001b10:	4c9c                	lw	a5,24(s1)
    80001b12:	cb91                	beqz	a5,80001b26 <allocproc+0x38>
      release(&p->lock);
    80001b14:	8526                	mv	a0,s1
    80001b16:	950ff0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b1a:	18048493          	addi	s1,s1,384
    80001b1e:	ff2496e3          	bne	s1,s2,80001b0a <allocproc+0x1c>
  return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	a899                	j	80001b7a <allocproc+0x8c>
  p->pid = allocpid();
    80001b26:	e71ff0ef          	jal	80001996 <allocpid>
    80001b2a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b2c:	4785                	li	a5,1
    80001b2e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001b30:	fcffe0ef          	jal	80000afe <kalloc>
    80001b34:	892a                	mv	s2,a0
    80001b36:	f8a8                	sd	a0,112(s1)
    80001b38:	c921                	beqz	a0,80001b88 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	e99ff0ef          	jal	800019d4 <proc_pagetable>
    80001b40:	892a                	mv	s2,a0
    80001b42:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    80001b44:	c931                	beqz	a0,80001b98 <allocproc+0xaa>
  memset(&p->context, 0, sizeof(p->context));
    80001b46:	07000613          	li	a2,112
    80001b4a:	4581                	li	a1,0
    80001b4c:	07848513          	addi	a0,s1,120
    80001b50:	952ff0ef          	jal	80000ca2 <memset>
  p->context.ra = (uint64)forkret;
    80001b54:	00000797          	auipc	a5,0x0
    80001b58:	daa78793          	addi	a5,a5,-598 # 800018fe <forkret>
    80001b5c:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001b5e:	6cbc                	ld	a5,88(s1)
    80001b60:	6705                	lui	a4,0x1
    80001b62:	97ba                	add	a5,a5,a4
    80001b64:	e0dc                	sd	a5,128(s1)
  p->queue_level = 0;   // new process starts at top priority
    80001b66:	0404a023          	sw	zero,64(s1)
  p->q_ticks     = 0;   // no ticks used yet
    80001b6a:	0404a223          	sw	zero,68(s1)
  p->wait_time   = 0;   // no waiting time yet
    80001b6e:	0404a423          	sw	zero,72(s1)
  p->n_run       = 0;   // not scheduled yet
    80001b72:	0404a623          	sw	zero,76(s1)
  p->total_ticks = 0;   // no CPU time used
    80001b76:	0404a823          	sw	zero,80(s1)
}
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	60e2                	ld	ra,24(sp)
    80001b7e:	6442                	ld	s0,16(sp)
    80001b80:	64a2                	ld	s1,8(sp)
    80001b82:	6902                	ld	s2,0(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret
    freeproc(p);
    80001b88:	8526                	mv	a0,s1
    80001b8a:	f15ff0ef          	jal	80001a9e <freeproc>
    release(&p->lock);
    80001b8e:	8526                	mv	a0,s1
    80001b90:	8d6ff0ef          	jal	80000c66 <release>
    return 0;
    80001b94:	84ca                	mv	s1,s2
    80001b96:	b7d5                	j	80001b7a <allocproc+0x8c>
    freeproc(p);
    80001b98:	8526                	mv	a0,s1
    80001b9a:	f05ff0ef          	jal	80001a9e <freeproc>
    release(&p->lock);
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	8c6ff0ef          	jal	80000c66 <release>
    return 0;
    80001ba4:	84ca                	mv	s1,s2
    80001ba6:	bfd1                	j	80001b7a <allocproc+0x8c>

0000000080001ba8 <userinit>:
{
    80001ba8:	1101                	addi	sp,sp,-32
    80001baa:	ec06                	sd	ra,24(sp)
    80001bac:	e822                	sd	s0,16(sp)
    80001bae:	e426                	sd	s1,8(sp)
    80001bb0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001bb2:	f3dff0ef          	jal	80001aee <allocproc>
    80001bb6:	84aa                	mv	s1,a0
  initproc = p;
    80001bb8:	00006797          	auipc	a5,0x6
    80001bbc:	d0a7b423          	sd	a0,-760(a5) # 800078c0 <initproc>
  p->cwd = namei("/");
    80001bc0:	00005517          	auipc	a0,0x5
    80001bc4:	5d050513          	addi	a0,a0,1488 # 80007190 <etext+0x190>
    80001bc8:	71d010ef          	jal	80003ae4 <namei>
    80001bcc:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80001bd0:	478d                	li	a5,3
    80001bd2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	890ff0ef          	jal	80000c66 <release>
}
    80001bda:	60e2                	ld	ra,24(sp)
    80001bdc:	6442                	ld	s0,16(sp)
    80001bde:	64a2                	ld	s1,8(sp)
    80001be0:	6105                	addi	sp,sp,32
    80001be2:	8082                	ret

0000000080001be4 <growproc>:
{
    80001be4:	1101                	addi	sp,sp,-32
    80001be6:	ec06                	sd	ra,24(sp)
    80001be8:	e822                	sd	s0,16(sp)
    80001bea:	e426                	sd	s1,8(sp)
    80001bec:	e04a                	sd	s2,0(sp)
    80001bee:	1000                	addi	s0,sp,32
    80001bf0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001bf2:	cddff0ef          	jal	800018ce <myproc>
    80001bf6:	84aa                	mv	s1,a0
  sz = p->sz;
    80001bf8:	712c                	ld	a1,96(a0)
  if(n > 0){
    80001bfa:	01204c63          	bgtz	s2,80001c12 <growproc+0x2e>
  } else if(n < 0){
    80001bfe:	02094463          	bltz	s2,80001c26 <growproc+0x42>
  p->sz = sz;
    80001c02:	f0ac                	sd	a1,96(s1)
  return 0;
    80001c04:	4501                	li	a0,0
}
    80001c06:	60e2                	ld	ra,24(sp)
    80001c08:	6442                	ld	s0,16(sp)
    80001c0a:	64a2                	ld	s1,8(sp)
    80001c0c:	6902                	ld	s2,0(sp)
    80001c0e:	6105                	addi	sp,sp,32
    80001c10:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c12:	4691                	li	a3,4
    80001c14:	00b90633          	add	a2,s2,a1
    80001c18:	7528                	ld	a0,104(a0)
    80001c1a:	e6eff0ef          	jal	80001288 <uvmalloc>
    80001c1e:	85aa                	mv	a1,a0
    80001c20:	f16d                	bnez	a0,80001c02 <growproc+0x1e>
      return -1;
    80001c22:	557d                	li	a0,-1
    80001c24:	b7cd                	j	80001c06 <growproc+0x22>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c26:	00b90633          	add	a2,s2,a1
    80001c2a:	7528                	ld	a0,104(a0)
    80001c2c:	e18ff0ef          	jal	80001244 <uvmdealloc>
    80001c30:	85aa                	mv	a1,a0
    80001c32:	bfc1                	j	80001c02 <growproc+0x1e>

0000000080001c34 <kfork>:
{
    80001c34:	7139                	addi	sp,sp,-64
    80001c36:	fc06                	sd	ra,56(sp)
    80001c38:	f822                	sd	s0,48(sp)
    80001c3a:	f04a                	sd	s2,32(sp)
    80001c3c:	e456                	sd	s5,8(sp)
    80001c3e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c40:	c8fff0ef          	jal	800018ce <myproc>
    80001c44:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001c46:	ea9ff0ef          	jal	80001aee <allocproc>
    80001c4a:	0e050a63          	beqz	a0,80001d3e <kfork+0x10a>
    80001c4e:	e852                	sd	s4,16(sp)
    80001c50:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001c52:	060ab603          	ld	a2,96(s5)
    80001c56:	752c                	ld	a1,104(a0)
    80001c58:	068ab503          	ld	a0,104(s5)
    80001c5c:	f64ff0ef          	jal	800013c0 <uvmcopy>
    80001c60:	04054a63          	bltz	a0,80001cb4 <kfork+0x80>
    80001c64:	f426                	sd	s1,40(sp)
    80001c66:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001c68:	060ab783          	ld	a5,96(s5)
    80001c6c:	06fa3023          	sd	a5,96(s4)
  *(np->trapframe) = *(p->trapframe);
    80001c70:	070ab683          	ld	a3,112(s5)
    80001c74:	87b6                	mv	a5,a3
    80001c76:	070a3703          	ld	a4,112(s4)
    80001c7a:	12068693          	addi	a3,a3,288
    80001c7e:	0007b803          	ld	a6,0(a5)
    80001c82:	6788                	ld	a0,8(a5)
    80001c84:	6b8c                	ld	a1,16(a5)
    80001c86:	6f90                	ld	a2,24(a5)
    80001c88:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001c8c:	e708                	sd	a0,8(a4)
    80001c8e:	eb0c                	sd	a1,16(a4)
    80001c90:	ef10                	sd	a2,24(a4)
    80001c92:	02078793          	addi	a5,a5,32
    80001c96:	02070713          	addi	a4,a4,32
    80001c9a:	fed792e3          	bne	a5,a3,80001c7e <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001c9e:	070a3783          	ld	a5,112(s4)
    80001ca2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ca6:	0e8a8493          	addi	s1,s5,232
    80001caa:	0e8a0913          	addi	s2,s4,232
    80001cae:	168a8993          	addi	s3,s5,360
    80001cb2:	a831                	j	80001cce <kfork+0x9a>
    freeproc(np);
    80001cb4:	8552                	mv	a0,s4
    80001cb6:	de9ff0ef          	jal	80001a9e <freeproc>
    release(&np->lock);
    80001cba:	8552                	mv	a0,s4
    80001cbc:	fabfe0ef          	jal	80000c66 <release>
    return -1;
    80001cc0:	597d                	li	s2,-1
    80001cc2:	6a42                	ld	s4,16(sp)
    80001cc4:	a0b5                	j	80001d30 <kfork+0xfc>
  for(i = 0; i < NOFILE; i++)
    80001cc6:	04a1                	addi	s1,s1,8
    80001cc8:	0921                	addi	s2,s2,8
    80001cca:	01348963          	beq	s1,s3,80001cdc <kfork+0xa8>
    if(p->ofile[i])
    80001cce:	6088                	ld	a0,0(s1)
    80001cd0:	d97d                	beqz	a0,80001cc6 <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001cd2:	3ac020ef          	jal	8000407e <filedup>
    80001cd6:	00a93023          	sd	a0,0(s2)
    80001cda:	b7f5                	j	80001cc6 <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001cdc:	168ab503          	ld	a0,360(s5)
    80001ce0:	5b8010ef          	jal	80003298 <idup>
    80001ce4:	16aa3423          	sd	a0,360(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ce8:	4641                	li	a2,16
    80001cea:	170a8593          	addi	a1,s5,368
    80001cee:	170a0513          	addi	a0,s4,368
    80001cf2:	8eeff0ef          	jal	80000de0 <safestrcpy>
  pid = np->pid;
    80001cf6:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001cfa:	8552                	mv	a0,s4
    80001cfc:	f6bfe0ef          	jal	80000c66 <release>
  acquire(&wait_lock);
    80001d00:	0000e497          	auipc	s1,0xe
    80001d04:	ce048493          	addi	s1,s1,-800 # 8000f9e0 <wait_lock>
    80001d08:	8526                	mv	a0,s1
    80001d0a:	ec5fe0ef          	jal	80000bce <acquire>
  np->parent = p;
    80001d0e:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001d12:	8526                	mv	a0,s1
    80001d14:	f53fe0ef          	jal	80000c66 <release>
  acquire(&np->lock);
    80001d18:	8552                	mv	a0,s4
    80001d1a:	eb5fe0ef          	jal	80000bce <acquire>
  np->state = RUNNABLE;
    80001d1e:	478d                	li	a5,3
    80001d20:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d24:	8552                	mv	a0,s4
    80001d26:	f41fe0ef          	jal	80000c66 <release>
  return pid;
    80001d2a:	74a2                	ld	s1,40(sp)
    80001d2c:	69e2                	ld	s3,24(sp)
    80001d2e:	6a42                	ld	s4,16(sp)
}
    80001d30:	854a                	mv	a0,s2
    80001d32:	70e2                	ld	ra,56(sp)
    80001d34:	7442                	ld	s0,48(sp)
    80001d36:	7902                	ld	s2,32(sp)
    80001d38:	6aa2                	ld	s5,8(sp)
    80001d3a:	6121                	addi	sp,sp,64
    80001d3c:	8082                	ret
    return -1;
    80001d3e:	597d                	li	s2,-1
    80001d40:	bfc5                	j	80001d30 <kfork+0xfc>

0000000080001d42 <scheduler>:
{
    80001d42:	715d                	addi	sp,sp,-80
    80001d44:	e486                	sd	ra,72(sp)
    80001d46:	e0a2                	sd	s0,64(sp)
    80001d48:	fc26                	sd	s1,56(sp)
    80001d4a:	f84a                	sd	s2,48(sp)
    80001d4c:	f44e                	sd	s3,40(sp)
    80001d4e:	f052                	sd	s4,32(sp)
    80001d50:	ec56                	sd	s5,24(sp)
    80001d52:	e85a                	sd	s6,16(sp)
    80001d54:	e45e                	sd	s7,8(sp)
    80001d56:	e062                	sd	s8,0(sp)
    80001d58:	0880                	addi	s0,sp,80
    80001d5a:	8792                	mv	a5,tp
  int id = r_tp();
    80001d5c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d5e:	00779b93          	slli	s7,a5,0x7
    80001d62:	0000e717          	auipc	a4,0xe
    80001d66:	c6670713          	addi	a4,a4,-922 # 8000f9c8 <pid_lock>
    80001d6a:	975e                	add	a4,a4,s7
    80001d6c:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &chosen->context);
    80001d70:	0000e717          	auipc	a4,0xe
    80001d74:	c9070713          	addi	a4,a4,-880 # 8000fa00 <cpus+0x8>
    80001d78:	9bba                	add	s7,s7,a4
    for(level = 0; level < MLFQ_LEVELS; level++){
    80001d7a:	4b01                	li	s6,0
        if(p->state == RUNNABLE && p->queue_level == level){
    80001d7c:	490d                	li	s2,3
      for(p = proc; p < &proc[NPROC]; p++){
    80001d7e:	00014997          	auipc	s3,0x14
    80001d82:	07a98993          	addi	s3,s3,122 # 80015df8 <tickslock>
      c->proc = chosen;
    80001d86:	079e                	slli	a5,a5,0x7
    80001d88:	0000ea97          	auipc	s5,0xe
    80001d8c:	c40a8a93          	addi	s5,s5,-960 # 8000f9c8 <pid_lock>
    80001d90:	9abe                	add	s5,s5,a5
      int quantum = mlfq_quantum[chosen->queue_level];
    80001d92:	00006c17          	auipc	s8,0x6
    80001d96:	9dec0c13          	addi	s8,s8,-1570 # 80007770 <mlfq_quantum>
    80001d9a:	a86d                	j	80001e54 <scheduler+0x112>
        release(&p->lock);
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	ec9fe0ef          	jal	80000c66 <release>
      for(p = proc; p < &proc[NPROC]; p++){
    80001da2:	18048493          	addi	s1,s1,384
    80001da6:	0d348363          	beq	s1,s3,80001e6c <scheduler+0x12a>
        acquire(&p->lock);
    80001daa:	8526                	mv	a0,s1
    80001dac:	e23fe0ef          	jal	80000bce <acquire>
        if(p->state == RUNNABLE && p->queue_level == level){
    80001db0:	4c9c                	lw	a5,24(s1)
    80001db2:	ff2795e3          	bne	a5,s2,80001d9c <scheduler+0x5a>
    80001db6:	40bc                	lw	a5,64(s1)
    80001db8:	ff4792e3          	bne	a5,s4,80001d9c <scheduler+0x5a>
      printf("Scheduler: pid=%d, queue_level=%d, times scheduled=%d, CPU_ticks=%d\n", chosen->pid,chosen->queue_level,chosen->n_run,chosen->total_ticks);
    80001dbc:	48b8                	lw	a4,80(s1)
    80001dbe:	44f4                	lw	a3,76(s1)
    80001dc0:	40b0                	lw	a2,64(s1)
    80001dc2:	588c                	lw	a1,48(s1)
    80001dc4:	00005517          	auipc	a0,0x5
    80001dc8:	3d450513          	addi	a0,a0,980 # 80007198 <etext+0x198>
    80001dcc:	f2efe0ef          	jal	800004fa <printf>
      int prev_total = chosen->total_ticks;
    80001dd0:	0504aa03          	lw	s4,80(s1)
      chosen->state = RUNNING;
    80001dd4:	4791                	li	a5,4
    80001dd6:	cc9c                	sw	a5,24(s1)
      c->proc = chosen;
    80001dd8:	029ab823          	sd	s1,48(s5)
      chosen->n_run++;    // stats
    80001ddc:	44fc                	lw	a5,76(s1)
    80001dde:	2785                	addiw	a5,a5,1
    80001de0:	c4fc                	sw	a5,76(s1)
      swtch(&c->context, &chosen->context);
    80001de2:	07848593          	addi	a1,s1,120
    80001de6:	855e                	mv	a0,s7
    80001de8:	63a000ef          	jal	80002422 <swtch>
      c->proc = 0;
    80001dec:	020ab823          	sd	zero,48(s5)
      int used = chosen->total_ticks - prev_total;
    80001df0:	48bc                	lw	a5,80(s1)
    80001df2:	414787bb          	subw	a5,a5,s4
      if(used < 0) used = 0;
    80001df6:	0007871b          	sext.w	a4,a5
    80001dfa:	fff74713          	not	a4,a4
    80001dfe:	977d                	srai	a4,a4,0x3f
    80001e00:	8ff9                	and	a5,a5,a4
      chosen->q_ticks += used;
    80001e02:	40f8                	lw	a4,68(s1)
    80001e04:	9fb9                	addw	a5,a5,a4
    80001e06:	0007869b          	sext.w	a3,a5
    80001e0a:	c0fc                	sw	a5,68(s1)
      int quantum = mlfq_quantum[chosen->queue_level];
    80001e0c:	40b8                	lw	a4,64(s1)
    80001e0e:	00271793          	slli	a5,a4,0x2
    80001e12:	97e2                	add	a5,a5,s8
      if(chosen->q_ticks >= quantum){
    80001e14:	439c                	lw	a5,0(a5)
    80001e16:	00f6c763          	blt	a3,a5,80001e24 <scheduler+0xe2>
        if(chosen->queue_level < MLFQ_LEVELS - 1)
    80001e1a:	4785                	li	a5,1
    80001e1c:	04e7dc63          	bge	a5,a4,80001e74 <scheduler+0x132>
        chosen->q_ticks = 0;
    80001e20:	0404a223          	sw	zero,68(s1)
      chosen->wait_time = 0;
    80001e24:	0404a423          	sw	zero,72(s1)
      release(&chosen->lock);
    80001e28:	8526                	mv	a0,s1
    80001e2a:	e3dfe0ef          	jal	80000c66 <release>
    for(level = 0; level < MLFQ_LEVELS; level++){
    80001e2e:	0000e497          	auipc	s1,0xe
    80001e32:	fca48493          	addi	s1,s1,-54 # 8000fdf8 <proc>
      acquire(&p->lock);
    80001e36:	8526                	mv	a0,s1
    80001e38:	d97fe0ef          	jal	80000bce <acquire>
      if(p->state == RUNNABLE){
    80001e3c:	4c9c                	lw	a5,24(s1)
    80001e3e:	03278e63          	beq	a5,s2,80001e7a <scheduler+0x138>
        p->wait_time = 0;
    80001e42:	0404a423          	sw	zero,72(s1)
      release(&p->lock);
    80001e46:	8526                	mv	a0,s1
    80001e48:	e1ffe0ef          	jal	80000c66 <release>
    for(p = proc; p < &proc[NPROC]; p++){
    80001e4c:	18048493          	addi	s1,s1,384
    80001e50:	ff3493e3          	bne	s1,s3,80001e36 <scheduler+0xf4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e5c:	10079073          	csrw	sstatus,a5
    for(level = 0; level < MLFQ_LEVELS; level++){
    80001e60:	8a5a                	mv	s4,s6
      for(p = proc; p < &proc[NPROC]; p++){
    80001e62:	0000e497          	auipc	s1,0xe
    80001e66:	f9648493          	addi	s1,s1,-106 # 8000fdf8 <proc>
    80001e6a:	b781                	j	80001daa <scheduler+0x68>
    for(level = 0; level < MLFQ_LEVELS; level++){
    80001e6c:	2a05                	addiw	s4,s4,1
    80001e6e:	ff2a1ae3          	bne	s4,s2,80001e62 <scheduler+0x120>
    80001e72:	bf75                	j	80001e2e <scheduler+0xec>
          chosen->queue_level++;
    80001e74:	2705                	addiw	a4,a4,1
    80001e76:	c0b8                	sw	a4,64(s1)
    80001e78:	b765                	j	80001e20 <scheduler+0xde>
        p->wait_time++;
    80001e7a:	44bc                	lw	a5,72(s1)
    80001e7c:	2785                	addiw	a5,a5,1
    80001e7e:	0007871b          	sext.w	a4,a5
    80001e82:	c4bc                	sw	a5,72(s1)
        if(p->wait_time >= AGING_THRESHOLD && p->queue_level > 0){
    80001e84:	0c700793          	li	a5,199
    80001e88:	fae7dfe3          	bge	a5,a4,80001e46 <scheduler+0x104>
    80001e8c:	40bc                	lw	a5,64(s1)
    80001e8e:	faf05ce3          	blez	a5,80001e46 <scheduler+0x104>
          p->queue_level--;
    80001e92:	37fd                	addiw	a5,a5,-1
    80001e94:	c0bc                	sw	a5,64(s1)
          p->q_ticks = 0;
    80001e96:	0404a223          	sw	zero,68(s1)
          p->wait_time = 0;
    80001e9a:	0404a423          	sw	zero,72(s1)
    80001e9e:	b765                	j	80001e46 <scheduler+0x104>

0000000080001ea0 <sched>:
{
    80001ea0:	7179                	addi	sp,sp,-48
    80001ea2:	f406                	sd	ra,40(sp)
    80001ea4:	f022                	sd	s0,32(sp)
    80001ea6:	ec26                	sd	s1,24(sp)
    80001ea8:	e84a                	sd	s2,16(sp)
    80001eaa:	e44e                	sd	s3,8(sp)
    80001eac:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001eae:	a21ff0ef          	jal	800018ce <myproc>
    80001eb2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001eb4:	cb1fe0ef          	jal	80000b64 <holding>
    80001eb8:	c92d                	beqz	a0,80001f2a <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001eba:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ebc:	2781                	sext.w	a5,a5
    80001ebe:	079e                	slli	a5,a5,0x7
    80001ec0:	0000e717          	auipc	a4,0xe
    80001ec4:	b0870713          	addi	a4,a4,-1272 # 8000f9c8 <pid_lock>
    80001ec8:	97ba                	add	a5,a5,a4
    80001eca:	0a87a703          	lw	a4,168(a5)
    80001ece:	4785                	li	a5,1
    80001ed0:	06f71363          	bne	a4,a5,80001f36 <sched+0x96>
  if(p->state == RUNNING)
    80001ed4:	4c98                	lw	a4,24(s1)
    80001ed6:	4791                	li	a5,4
    80001ed8:	06f70563          	beq	a4,a5,80001f42 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001edc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ee0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001ee2:	e7b5                	bnez	a5,80001f4e <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ee4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ee6:	0000e917          	auipc	s2,0xe
    80001eea:	ae290913          	addi	s2,s2,-1310 # 8000f9c8 <pid_lock>
    80001eee:	2781                	sext.w	a5,a5
    80001ef0:	079e                	slli	a5,a5,0x7
    80001ef2:	97ca                	add	a5,a5,s2
    80001ef4:	0ac7a983          	lw	s3,172(a5)
    80001ef8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001efa:	2781                	sext.w	a5,a5
    80001efc:	079e                	slli	a5,a5,0x7
    80001efe:	0000e597          	auipc	a1,0xe
    80001f02:	b0258593          	addi	a1,a1,-1278 # 8000fa00 <cpus+0x8>
    80001f06:	95be                	add	a1,a1,a5
    80001f08:	07848513          	addi	a0,s1,120
    80001f0c:	516000ef          	jal	80002422 <swtch>
    80001f10:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f12:	2781                	sext.w	a5,a5
    80001f14:	079e                	slli	a5,a5,0x7
    80001f16:	993e                	add	s2,s2,a5
    80001f18:	0b392623          	sw	s3,172(s2)
}
    80001f1c:	70a2                	ld	ra,40(sp)
    80001f1e:	7402                	ld	s0,32(sp)
    80001f20:	64e2                	ld	s1,24(sp)
    80001f22:	6942                	ld	s2,16(sp)
    80001f24:	69a2                	ld	s3,8(sp)
    80001f26:	6145                	addi	sp,sp,48
    80001f28:	8082                	ret
    panic("sched p->lock");
    80001f2a:	00005517          	auipc	a0,0x5
    80001f2e:	2b650513          	addi	a0,a0,694 # 800071e0 <etext+0x1e0>
    80001f32:	8affe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    80001f36:	00005517          	auipc	a0,0x5
    80001f3a:	2ba50513          	addi	a0,a0,698 # 800071f0 <etext+0x1f0>
    80001f3e:	8a3fe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    80001f42:	00005517          	auipc	a0,0x5
    80001f46:	2be50513          	addi	a0,a0,702 # 80007200 <etext+0x200>
    80001f4a:	897fe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80001f4e:	00005517          	auipc	a0,0x5
    80001f52:	2c250513          	addi	a0,a0,706 # 80007210 <etext+0x210>
    80001f56:	88bfe0ef          	jal	800007e0 <panic>

0000000080001f5a <yield>:
{
    80001f5a:	1101                	addi	sp,sp,-32
    80001f5c:	ec06                	sd	ra,24(sp)
    80001f5e:	e822                	sd	s0,16(sp)
    80001f60:	e426                	sd	s1,8(sp)
    80001f62:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f64:	96bff0ef          	jal	800018ce <myproc>
    80001f68:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f6a:	c65fe0ef          	jal	80000bce <acquire>
  p->state = RUNNABLE;
    80001f6e:	478d                	li	a5,3
    80001f70:	cc9c                	sw	a5,24(s1)
  sched();
    80001f72:	f2fff0ef          	jal	80001ea0 <sched>
  release(&p->lock);
    80001f76:	8526                	mv	a0,s1
    80001f78:	ceffe0ef          	jal	80000c66 <release>
}
    80001f7c:	60e2                	ld	ra,24(sp)
    80001f7e:	6442                	ld	s0,16(sp)
    80001f80:	64a2                	ld	s1,8(sp)
    80001f82:	6105                	addi	sp,sp,32
    80001f84:	8082                	ret

0000000080001f86 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001f86:	7179                	addi	sp,sp,-48
    80001f88:	f406                	sd	ra,40(sp)
    80001f8a:	f022                	sd	s0,32(sp)
    80001f8c:	ec26                	sd	s1,24(sp)
    80001f8e:	e84a                	sd	s2,16(sp)
    80001f90:	e44e                	sd	s3,8(sp)
    80001f92:	1800                	addi	s0,sp,48
    80001f94:	89aa                	mv	s3,a0
    80001f96:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f98:	937ff0ef          	jal	800018ce <myproc>
    80001f9c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001f9e:	c31fe0ef          	jal	80000bce <acquire>
  release(lk);
    80001fa2:	854a                	mv	a0,s2
    80001fa4:	cc3fe0ef          	jal	80000c66 <release>

  // Go to sleep.
  p->chan = chan;
    80001fa8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001fac:	4789                	li	a5,2
    80001fae:	cc9c                	sw	a5,24(s1)

  sched();
    80001fb0:	ef1ff0ef          	jal	80001ea0 <sched>

  // Tidy up.
  p->chan = 0;
    80001fb4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001fb8:	8526                	mv	a0,s1
    80001fba:	cadfe0ef          	jal	80000c66 <release>
  acquire(lk);
    80001fbe:	854a                	mv	a0,s2
    80001fc0:	c0ffe0ef          	jal	80000bce <acquire>
}
    80001fc4:	70a2                	ld	ra,40(sp)
    80001fc6:	7402                	ld	s0,32(sp)
    80001fc8:	64e2                	ld	s1,24(sp)
    80001fca:	6942                	ld	s2,16(sp)
    80001fcc:	69a2                	ld	s3,8(sp)
    80001fce:	6145                	addi	sp,sp,48
    80001fd0:	8082                	ret

0000000080001fd2 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001fd2:	7139                	addi	sp,sp,-64
    80001fd4:	fc06                	sd	ra,56(sp)
    80001fd6:	f822                	sd	s0,48(sp)
    80001fd8:	f426                	sd	s1,40(sp)
    80001fda:	f04a                	sd	s2,32(sp)
    80001fdc:	ec4e                	sd	s3,24(sp)
    80001fde:	e852                	sd	s4,16(sp)
    80001fe0:	e456                	sd	s5,8(sp)
    80001fe2:	0080                	addi	s0,sp,64
    80001fe4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001fe6:	0000e497          	auipc	s1,0xe
    80001fea:	e1248493          	addi	s1,s1,-494 # 8000fdf8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001fee:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001ff0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ff2:	00014917          	auipc	s2,0x14
    80001ff6:	e0690913          	addi	s2,s2,-506 # 80015df8 <tickslock>
    80001ffa:	a801                	j	8000200a <wakeup+0x38>

        // Extra MLFQ-related resets
        p->q_ticks = 0;   // reset quantum ticks
        p->wait_time = 0; // reset waiting time
      }
      release(&p->lock);
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	c69fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002002:	18048493          	addi	s1,s1,384
    80002006:	03248663          	beq	s1,s2,80002032 <wakeup+0x60>
    if(p != myproc()){
    8000200a:	8c5ff0ef          	jal	800018ce <myproc>
    8000200e:	fea48ae3          	beq	s1,a0,80002002 <wakeup+0x30>
      acquire(&p->lock);
    80002012:	8526                	mv	a0,s1
    80002014:	bbbfe0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002018:	4c9c                	lw	a5,24(s1)
    8000201a:	ff3791e3          	bne	a5,s3,80001ffc <wakeup+0x2a>
    8000201e:	709c                	ld	a5,32(s1)
    80002020:	fd479ee3          	bne	a5,s4,80001ffc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002024:	0154ac23          	sw	s5,24(s1)
        p->q_ticks = 0;   // reset quantum ticks
    80002028:	0404a223          	sw	zero,68(s1)
        p->wait_time = 0; // reset waiting time
    8000202c:	0404a423          	sw	zero,72(s1)
    80002030:	b7f1                	j	80001ffc <wakeup+0x2a>
    }
  }
}
    80002032:	70e2                	ld	ra,56(sp)
    80002034:	7442                	ld	s0,48(sp)
    80002036:	74a2                	ld	s1,40(sp)
    80002038:	7902                	ld	s2,32(sp)
    8000203a:	69e2                	ld	s3,24(sp)
    8000203c:	6a42                	ld	s4,16(sp)
    8000203e:	6aa2                	ld	s5,8(sp)
    80002040:	6121                	addi	sp,sp,64
    80002042:	8082                	ret

0000000080002044 <reparent>:
{
    80002044:	7179                	addi	sp,sp,-48
    80002046:	f406                	sd	ra,40(sp)
    80002048:	f022                	sd	s0,32(sp)
    8000204a:	ec26                	sd	s1,24(sp)
    8000204c:	e84a                	sd	s2,16(sp)
    8000204e:	e44e                	sd	s3,8(sp)
    80002050:	e052                	sd	s4,0(sp)
    80002052:	1800                	addi	s0,sp,48
    80002054:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002056:	0000e497          	auipc	s1,0xe
    8000205a:	da248493          	addi	s1,s1,-606 # 8000fdf8 <proc>
      pp->parent = initproc;
    8000205e:	00006a17          	auipc	s4,0x6
    80002062:	862a0a13          	addi	s4,s4,-1950 # 800078c0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002066:	00014997          	auipc	s3,0x14
    8000206a:	d9298993          	addi	s3,s3,-622 # 80015df8 <tickslock>
    8000206e:	a029                	j	80002078 <reparent+0x34>
    80002070:	18048493          	addi	s1,s1,384
    80002074:	01348b63          	beq	s1,s3,8000208a <reparent+0x46>
    if(pp->parent == p){
    80002078:	7c9c                	ld	a5,56(s1)
    8000207a:	ff279be3          	bne	a5,s2,80002070 <reparent+0x2c>
      pp->parent = initproc;
    8000207e:	000a3503          	ld	a0,0(s4)
    80002082:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002084:	f4fff0ef          	jal	80001fd2 <wakeup>
    80002088:	b7e5                	j	80002070 <reparent+0x2c>
}
    8000208a:	70a2                	ld	ra,40(sp)
    8000208c:	7402                	ld	s0,32(sp)
    8000208e:	64e2                	ld	s1,24(sp)
    80002090:	6942                	ld	s2,16(sp)
    80002092:	69a2                	ld	s3,8(sp)
    80002094:	6a02                	ld	s4,0(sp)
    80002096:	6145                	addi	sp,sp,48
    80002098:	8082                	ret

000000008000209a <kexit>:
{
    8000209a:	7179                	addi	sp,sp,-48
    8000209c:	f406                	sd	ra,40(sp)
    8000209e:	f022                	sd	s0,32(sp)
    800020a0:	ec26                	sd	s1,24(sp)
    800020a2:	e84a                	sd	s2,16(sp)
    800020a4:	e44e                	sd	s3,8(sp)
    800020a6:	e052                	sd	s4,0(sp)
    800020a8:	1800                	addi	s0,sp,48
    800020aa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020ac:	823ff0ef          	jal	800018ce <myproc>
    800020b0:	89aa                	mv	s3,a0
  if(p == initproc)
    800020b2:	00006797          	auipc	a5,0x6
    800020b6:	80e7b783          	ld	a5,-2034(a5) # 800078c0 <initproc>
    800020ba:	0e850493          	addi	s1,a0,232
    800020be:	16850913          	addi	s2,a0,360
    800020c2:	00a79f63          	bne	a5,a0,800020e0 <kexit+0x46>
    panic("init exiting");
    800020c6:	00005517          	auipc	a0,0x5
    800020ca:	16250513          	addi	a0,a0,354 # 80007228 <etext+0x228>
    800020ce:	f12fe0ef          	jal	800007e0 <panic>
      fileclose(f);
    800020d2:	7f3010ef          	jal	800040c4 <fileclose>
      p->ofile[fd] = 0;
    800020d6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020da:	04a1                	addi	s1,s1,8
    800020dc:	01248563          	beq	s1,s2,800020e6 <kexit+0x4c>
    if(p->ofile[fd]){
    800020e0:	6088                	ld	a0,0(s1)
    800020e2:	f965                	bnez	a0,800020d2 <kexit+0x38>
    800020e4:	bfdd                	j	800020da <kexit+0x40>
  begin_op();
    800020e6:	3d3010ef          	jal	80003cb8 <begin_op>
  iput(p->cwd);
    800020ea:	1689b503          	ld	a0,360(s3)
    800020ee:	362010ef          	jal	80003450 <iput>
  end_op();
    800020f2:	431010ef          	jal	80003d22 <end_op>
  p->cwd = 0;
    800020f6:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    800020fa:	0000e497          	auipc	s1,0xe
    800020fe:	8e648493          	addi	s1,s1,-1818 # 8000f9e0 <wait_lock>
    80002102:	8526                	mv	a0,s1
    80002104:	acbfe0ef          	jal	80000bce <acquire>
  reparent(p);
    80002108:	854e                	mv	a0,s3
    8000210a:	f3bff0ef          	jal	80002044 <reparent>
  wakeup(p->parent);
    8000210e:	0389b503          	ld	a0,56(s3)
    80002112:	ec1ff0ef          	jal	80001fd2 <wakeup>
  acquire(&p->lock);
    80002116:	854e                	mv	a0,s3
    80002118:	ab7fe0ef          	jal	80000bce <acquire>
  p->xstate = status;
    8000211c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002120:	4795                	li	a5,5
    80002122:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002126:	8526                	mv	a0,s1
    80002128:	b3ffe0ef          	jal	80000c66 <release>
  sched();
    8000212c:	d75ff0ef          	jal	80001ea0 <sched>
  panic("zombie exit");
    80002130:	00005517          	auipc	a0,0x5
    80002134:	10850513          	addi	a0,a0,264 # 80007238 <etext+0x238>
    80002138:	ea8fe0ef          	jal	800007e0 <panic>

000000008000213c <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    8000213c:	7179                	addi	sp,sp,-48
    8000213e:	f406                	sd	ra,40(sp)
    80002140:	f022                	sd	s0,32(sp)
    80002142:	ec26                	sd	s1,24(sp)
    80002144:	e84a                	sd	s2,16(sp)
    80002146:	e44e                	sd	s3,8(sp)
    80002148:	1800                	addi	s0,sp,48
    8000214a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000214c:	0000e497          	auipc	s1,0xe
    80002150:	cac48493          	addi	s1,s1,-852 # 8000fdf8 <proc>
    80002154:	00014997          	auipc	s3,0x14
    80002158:	ca498993          	addi	s3,s3,-860 # 80015df8 <tickslock>
    acquire(&p->lock);
    8000215c:	8526                	mv	a0,s1
    8000215e:	a71fe0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    80002162:	589c                	lw	a5,48(s1)
    80002164:	01278b63          	beq	a5,s2,8000217a <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	afdfe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000216e:	18048493          	addi	s1,s1,384
    80002172:	ff3495e3          	bne	s1,s3,8000215c <kkill+0x20>
  }
  return -1;
    80002176:	557d                	li	a0,-1
    80002178:	a819                	j	8000218e <kkill+0x52>
      p->killed = 1;
    8000217a:	4785                	li	a5,1
    8000217c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000217e:	4c98                	lw	a4,24(s1)
    80002180:	4789                	li	a5,2
    80002182:	00f70d63          	beq	a4,a5,8000219c <kkill+0x60>
      release(&p->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	adffe0ef          	jal	80000c66 <release>
      return 0;
    8000218c:	4501                	li	a0,0
}
    8000218e:	70a2                	ld	ra,40(sp)
    80002190:	7402                	ld	s0,32(sp)
    80002192:	64e2                	ld	s1,24(sp)
    80002194:	6942                	ld	s2,16(sp)
    80002196:	69a2                	ld	s3,8(sp)
    80002198:	6145                	addi	sp,sp,48
    8000219a:	8082                	ret
        p->state = RUNNABLE;
    8000219c:	478d                	li	a5,3
    8000219e:	cc9c                	sw	a5,24(s1)
    800021a0:	b7dd                	j	80002186 <kkill+0x4a>

00000000800021a2 <setkilled>:

void
setkilled(struct proc *p)
{
    800021a2:	1101                	addi	sp,sp,-32
    800021a4:	ec06                	sd	ra,24(sp)
    800021a6:	e822                	sd	s0,16(sp)
    800021a8:	e426                	sd	s1,8(sp)
    800021aa:	1000                	addi	s0,sp,32
    800021ac:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021ae:	a21fe0ef          	jal	80000bce <acquire>
  p->killed = 1;
    800021b2:	4785                	li	a5,1
    800021b4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	aaffe0ef          	jal	80000c66 <release>
}
    800021bc:	60e2                	ld	ra,24(sp)
    800021be:	6442                	ld	s0,16(sp)
    800021c0:	64a2                	ld	s1,8(sp)
    800021c2:	6105                	addi	sp,sp,32
    800021c4:	8082                	ret

00000000800021c6 <killed>:

int
killed(struct proc *p)
{
    800021c6:	1101                	addi	sp,sp,-32
    800021c8:	ec06                	sd	ra,24(sp)
    800021ca:	e822                	sd	s0,16(sp)
    800021cc:	e426                	sd	s1,8(sp)
    800021ce:	e04a                	sd	s2,0(sp)
    800021d0:	1000                	addi	s0,sp,32
    800021d2:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800021d4:	9fbfe0ef          	jal	80000bce <acquire>
  k = p->killed;
    800021d8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	a89fe0ef          	jal	80000c66 <release>
  return k;
}
    800021e2:	854a                	mv	a0,s2
    800021e4:	60e2                	ld	ra,24(sp)
    800021e6:	6442                	ld	s0,16(sp)
    800021e8:	64a2                	ld	s1,8(sp)
    800021ea:	6902                	ld	s2,0(sp)
    800021ec:	6105                	addi	sp,sp,32
    800021ee:	8082                	ret

00000000800021f0 <kwait>:
{
    800021f0:	715d                	addi	sp,sp,-80
    800021f2:	e486                	sd	ra,72(sp)
    800021f4:	e0a2                	sd	s0,64(sp)
    800021f6:	fc26                	sd	s1,56(sp)
    800021f8:	f84a                	sd	s2,48(sp)
    800021fa:	f44e                	sd	s3,40(sp)
    800021fc:	f052                	sd	s4,32(sp)
    800021fe:	ec56                	sd	s5,24(sp)
    80002200:	e85a                	sd	s6,16(sp)
    80002202:	e45e                	sd	s7,8(sp)
    80002204:	e062                	sd	s8,0(sp)
    80002206:	0880                	addi	s0,sp,80
    80002208:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000220a:	ec4ff0ef          	jal	800018ce <myproc>
    8000220e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002210:	0000d517          	auipc	a0,0xd
    80002214:	7d050513          	addi	a0,a0,2000 # 8000f9e0 <wait_lock>
    80002218:	9b7fe0ef          	jal	80000bce <acquire>
    havekids = 0;
    8000221c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000221e:	4a15                	li	s4,5
        havekids = 1;
    80002220:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002222:	00014997          	auipc	s3,0x14
    80002226:	bd698993          	addi	s3,s3,-1066 # 80015df8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000222a:	0000dc17          	auipc	s8,0xd
    8000222e:	7b6c0c13          	addi	s8,s8,1974 # 8000f9e0 <wait_lock>
    80002232:	a871                	j	800022ce <kwait+0xde>
          pid = pp->pid;
    80002234:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002238:	000b0c63          	beqz	s6,80002250 <kwait+0x60>
    8000223c:	4691                	li	a3,4
    8000223e:	02c48613          	addi	a2,s1,44
    80002242:	85da                	mv	a1,s6
    80002244:	06893503          	ld	a0,104(s2)
    80002248:	b9aff0ef          	jal	800015e2 <copyout>
    8000224c:	02054b63          	bltz	a0,80002282 <kwait+0x92>
          freeproc(pp);
    80002250:	8526                	mv	a0,s1
    80002252:	84dff0ef          	jal	80001a9e <freeproc>
          release(&pp->lock);
    80002256:	8526                	mv	a0,s1
    80002258:	a0ffe0ef          	jal	80000c66 <release>
          release(&wait_lock);
    8000225c:	0000d517          	auipc	a0,0xd
    80002260:	78450513          	addi	a0,a0,1924 # 8000f9e0 <wait_lock>
    80002264:	a03fe0ef          	jal	80000c66 <release>
}
    80002268:	854e                	mv	a0,s3
    8000226a:	60a6                	ld	ra,72(sp)
    8000226c:	6406                	ld	s0,64(sp)
    8000226e:	74e2                	ld	s1,56(sp)
    80002270:	7942                	ld	s2,48(sp)
    80002272:	79a2                	ld	s3,40(sp)
    80002274:	7a02                	ld	s4,32(sp)
    80002276:	6ae2                	ld	s5,24(sp)
    80002278:	6b42                	ld	s6,16(sp)
    8000227a:	6ba2                	ld	s7,8(sp)
    8000227c:	6c02                	ld	s8,0(sp)
    8000227e:	6161                	addi	sp,sp,80
    80002280:	8082                	ret
            release(&pp->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	9e3fe0ef          	jal	80000c66 <release>
            release(&wait_lock);
    80002288:	0000d517          	auipc	a0,0xd
    8000228c:	75850513          	addi	a0,a0,1880 # 8000f9e0 <wait_lock>
    80002290:	9d7fe0ef          	jal	80000c66 <release>
            return -1;
    80002294:	59fd                	li	s3,-1
    80002296:	bfc9                	j	80002268 <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002298:	18048493          	addi	s1,s1,384
    8000229c:	03348063          	beq	s1,s3,800022bc <kwait+0xcc>
      if(pp->parent == p){
    800022a0:	7c9c                	ld	a5,56(s1)
    800022a2:	ff279be3          	bne	a5,s2,80002298 <kwait+0xa8>
        acquire(&pp->lock);
    800022a6:	8526                	mv	a0,s1
    800022a8:	927fe0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    800022ac:	4c9c                	lw	a5,24(s1)
    800022ae:	f94783e3          	beq	a5,s4,80002234 <kwait+0x44>
        release(&pp->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	9b3fe0ef          	jal	80000c66 <release>
        havekids = 1;
    800022b8:	8756                	mv	a4,s5
    800022ba:	bff9                	j	80002298 <kwait+0xa8>
    if(!havekids || killed(p)){
    800022bc:	cf19                	beqz	a4,800022da <kwait+0xea>
    800022be:	854a                	mv	a0,s2
    800022c0:	f07ff0ef          	jal	800021c6 <killed>
    800022c4:	e919                	bnez	a0,800022da <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022c6:	85e2                	mv	a1,s8
    800022c8:	854a                	mv	a0,s2
    800022ca:	cbdff0ef          	jal	80001f86 <sleep>
    havekids = 0;
    800022ce:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022d0:	0000e497          	auipc	s1,0xe
    800022d4:	b2848493          	addi	s1,s1,-1240 # 8000fdf8 <proc>
    800022d8:	b7e1                	j	800022a0 <kwait+0xb0>
      release(&wait_lock);
    800022da:	0000d517          	auipc	a0,0xd
    800022de:	70650513          	addi	a0,a0,1798 # 8000f9e0 <wait_lock>
    800022e2:	985fe0ef          	jal	80000c66 <release>
      return -1;
    800022e6:	59fd                	li	s3,-1
    800022e8:	b741                	j	80002268 <kwait+0x78>

00000000800022ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800022ea:	7179                	addi	sp,sp,-48
    800022ec:	f406                	sd	ra,40(sp)
    800022ee:	f022                	sd	s0,32(sp)
    800022f0:	ec26                	sd	s1,24(sp)
    800022f2:	e84a                	sd	s2,16(sp)
    800022f4:	e44e                	sd	s3,8(sp)
    800022f6:	e052                	sd	s4,0(sp)
    800022f8:	1800                	addi	s0,sp,48
    800022fa:	84aa                	mv	s1,a0
    800022fc:	892e                	mv	s2,a1
    800022fe:	89b2                	mv	s3,a2
    80002300:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002302:	dccff0ef          	jal	800018ce <myproc>
  if(user_dst){
    80002306:	cc99                	beqz	s1,80002324 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002308:	86d2                	mv	a3,s4
    8000230a:	864e                	mv	a2,s3
    8000230c:	85ca                	mv	a1,s2
    8000230e:	7528                	ld	a0,104(a0)
    80002310:	ad2ff0ef          	jal	800015e2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002314:	70a2                	ld	ra,40(sp)
    80002316:	7402                	ld	s0,32(sp)
    80002318:	64e2                	ld	s1,24(sp)
    8000231a:	6942                	ld	s2,16(sp)
    8000231c:	69a2                	ld	s3,8(sp)
    8000231e:	6a02                	ld	s4,0(sp)
    80002320:	6145                	addi	sp,sp,48
    80002322:	8082                	ret
    memmove((char *)dst, src, len);
    80002324:	000a061b          	sext.w	a2,s4
    80002328:	85ce                	mv	a1,s3
    8000232a:	854a                	mv	a0,s2
    8000232c:	9d3fe0ef          	jal	80000cfe <memmove>
    return 0;
    80002330:	8526                	mv	a0,s1
    80002332:	b7cd                	j	80002314 <either_copyout+0x2a>

0000000080002334 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002334:	7179                	addi	sp,sp,-48
    80002336:	f406                	sd	ra,40(sp)
    80002338:	f022                	sd	s0,32(sp)
    8000233a:	ec26                	sd	s1,24(sp)
    8000233c:	e84a                	sd	s2,16(sp)
    8000233e:	e44e                	sd	s3,8(sp)
    80002340:	e052                	sd	s4,0(sp)
    80002342:	1800                	addi	s0,sp,48
    80002344:	892a                	mv	s2,a0
    80002346:	84ae                	mv	s1,a1
    80002348:	89b2                	mv	s3,a2
    8000234a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000234c:	d82ff0ef          	jal	800018ce <myproc>
  if(user_src){
    80002350:	cc99                	beqz	s1,8000236e <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002352:	86d2                	mv	a3,s4
    80002354:	864e                	mv	a2,s3
    80002356:	85ca                	mv	a1,s2
    80002358:	7528                	ld	a0,104(a0)
    8000235a:	b6cff0ef          	jal	800016c6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000235e:	70a2                	ld	ra,40(sp)
    80002360:	7402                	ld	s0,32(sp)
    80002362:	64e2                	ld	s1,24(sp)
    80002364:	6942                	ld	s2,16(sp)
    80002366:	69a2                	ld	s3,8(sp)
    80002368:	6a02                	ld	s4,0(sp)
    8000236a:	6145                	addi	sp,sp,48
    8000236c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000236e:	000a061b          	sext.w	a2,s4
    80002372:	85ce                	mv	a1,s3
    80002374:	854a                	mv	a0,s2
    80002376:	989fe0ef          	jal	80000cfe <memmove>
    return 0;
    8000237a:	8526                	mv	a0,s1
    8000237c:	b7cd                	j	8000235e <either_copyin+0x2a>

000000008000237e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000237e:	715d                	addi	sp,sp,-80
    80002380:	e486                	sd	ra,72(sp)
    80002382:	e0a2                	sd	s0,64(sp)
    80002384:	fc26                	sd	s1,56(sp)
    80002386:	f84a                	sd	s2,48(sp)
    80002388:	f44e                	sd	s3,40(sp)
    8000238a:	f052                	sd	s4,32(sp)
    8000238c:	ec56                	sd	s5,24(sp)
    8000238e:	e85a                	sd	s6,16(sp)
    80002390:	e45e                	sd	s7,8(sp)
    80002392:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002394:	00005517          	auipc	a0,0x5
    80002398:	ce450513          	addi	a0,a0,-796 # 80007078 <etext+0x78>
    8000239c:	95efe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800023a0:	0000e497          	auipc	s1,0xe
    800023a4:	bc848493          	addi	s1,s1,-1080 # 8000ff68 <proc+0x170>
    800023a8:	00014917          	auipc	s2,0x14
    800023ac:	bc090913          	addi	s2,s2,-1088 # 80015f68 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023b0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800023b2:	00005997          	auipc	s3,0x5
    800023b6:	e9698993          	addi	s3,s3,-362 # 80007248 <etext+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800023ba:	00005a97          	auipc	s5,0x5
    800023be:	e96a8a93          	addi	s5,s5,-362 # 80007250 <etext+0x250>
    printf("\n");
    800023c2:	00005a17          	auipc	s4,0x5
    800023c6:	cb6a0a13          	addi	s4,s4,-842 # 80007078 <etext+0x78>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023ca:	00005b97          	auipc	s7,0x5
    800023ce:	3a6b8b93          	addi	s7,s7,934 # 80007770 <mlfq_quantum>
    800023d2:	a829                	j	800023ec <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    800023d4:	ec06a583          	lw	a1,-320(a3)
    800023d8:	8556                	mv	a0,s5
    800023da:	920fe0ef          	jal	800004fa <printf>
    printf("\n");
    800023de:	8552                	mv	a0,s4
    800023e0:	91afe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800023e4:	18048493          	addi	s1,s1,384
    800023e8:	03248263          	beq	s1,s2,8000240c <procdump+0x8e>
    if(p->state == UNUSED)
    800023ec:	86a6                	mv	a3,s1
    800023ee:	ea84a783          	lw	a5,-344(s1)
    800023f2:	dbed                	beqz	a5,800023e4 <procdump+0x66>
      state = "???";
    800023f4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023f6:	fcfb6fe3          	bltu	s6,a5,800023d4 <procdump+0x56>
    800023fa:	02079713          	slli	a4,a5,0x20
    800023fe:	01d75793          	srli	a5,a4,0x1d
    80002402:	97de                	add	a5,a5,s7
    80002404:	6b90                	ld	a2,16(a5)
    80002406:	f679                	bnez	a2,800023d4 <procdump+0x56>
      state = "???";
    80002408:	864e                	mv	a2,s3
    8000240a:	b7e9                	j	800023d4 <procdump+0x56>
  }
}
    8000240c:	60a6                	ld	ra,72(sp)
    8000240e:	6406                	ld	s0,64(sp)
    80002410:	74e2                	ld	s1,56(sp)
    80002412:	7942                	ld	s2,48(sp)
    80002414:	79a2                	ld	s3,40(sp)
    80002416:	7a02                	ld	s4,32(sp)
    80002418:	6ae2                	ld	s5,24(sp)
    8000241a:	6b42                	ld	s6,16(sp)
    8000241c:	6ba2                	ld	s7,8(sp)
    8000241e:	6161                	addi	sp,sp,80
    80002420:	8082                	ret

0000000080002422 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    80002422:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80002426:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    8000242a:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    8000242c:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    8000242e:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80002432:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80002436:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    8000243a:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    8000243e:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80002442:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80002446:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    8000244a:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    8000244e:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002452:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80002456:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    8000245a:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    8000245e:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002460:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002462:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80002466:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    8000246a:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    8000246e:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    80002472:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    80002476:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    8000247a:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    8000247e:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80002482:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80002486:	0685bd83          	ld	s11,104(a1)
        
        ret
    8000248a:	8082                	ret

000000008000248c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000248c:	1141                	addi	sp,sp,-16
    8000248e:	e406                	sd	ra,8(sp)
    80002490:	e022                	sd	s0,0(sp)
    80002492:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002494:	00005597          	auipc	a1,0x5
    80002498:	dfc58593          	addi	a1,a1,-516 # 80007290 <etext+0x290>
    8000249c:	00014517          	auipc	a0,0x14
    800024a0:	95c50513          	addi	a0,a0,-1700 # 80015df8 <tickslock>
    800024a4:	eaafe0ef          	jal	80000b4e <initlock>
}
    800024a8:	60a2                	ld	ra,8(sp)
    800024aa:	6402                	ld	s0,0(sp)
    800024ac:	0141                	addi	sp,sp,16
    800024ae:	8082                	ret

00000000800024b0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800024b0:	1141                	addi	sp,sp,-16
    800024b2:	e422                	sd	s0,8(sp)
    800024b4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800024b6:	00003797          	auipc	a5,0x3
    800024ba:	f7a78793          	addi	a5,a5,-134 # 80005430 <kernelvec>
    800024be:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800024c2:	6422                	ld	s0,8(sp)
    800024c4:	0141                	addi	sp,sp,16
    800024c6:	8082                	ret

00000000800024c8 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800024c8:	1141                	addi	sp,sp,-16
    800024ca:	e406                	sd	ra,8(sp)
    800024cc:	e022                	sd	s0,0(sp)
    800024ce:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800024d0:	bfeff0ef          	jal	800018ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800024d8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024da:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800024de:	04000737          	lui	a4,0x4000
    800024e2:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800024e4:	0732                	slli	a4,a4,0xc
    800024e6:	00004797          	auipc	a5,0x4
    800024ea:	b1a78793          	addi	a5,a5,-1254 # 80006000 <_trampoline>
    800024ee:	00004697          	auipc	a3,0x4
    800024f2:	b1268693          	addi	a3,a3,-1262 # 80006000 <_trampoline>
    800024f6:	8f95                	sub	a5,a5,a3
    800024f8:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    800024fa:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800024fe:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002500:	18002773          	csrr	a4,satp
    80002504:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002506:	7938                	ld	a4,112(a0)
    80002508:	6d3c                	ld	a5,88(a0)
    8000250a:	6685                	lui	a3,0x1
    8000250c:	97b6                	add	a5,a5,a3
    8000250e:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002510:	793c                	ld	a5,112(a0)
    80002512:	00000717          	auipc	a4,0x0
    80002516:	11270713          	addi	a4,a4,274 # 80002624 <usertrap>
    8000251a:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000251c:	793c                	ld	a5,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000251e:	8712                	mv	a4,tp
    80002520:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002522:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002526:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000252a:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000252e:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002532:	793c                	ld	a5,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002534:	6f9c                	ld	a5,24(a5)
    80002536:	14179073          	csrw	sepc,a5
}
    8000253a:	60a2                	ld	ra,8(sp)
    8000253c:	6402                	ld	s0,0(sp)
    8000253e:	0141                	addi	sp,sp,16
    80002540:	8082                	ret

0000000080002542 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002542:	1101                	addi	sp,sp,-32
    80002544:	ec06                	sd	ra,24(sp)
    80002546:	e822                	sd	s0,16(sp)
    80002548:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    8000254a:	b58ff0ef          	jal	800018a2 <cpuid>
    8000254e:	c50d                	beqz	a0,80002578 <clockintr+0x36>
    ticks++;
    wakeup(&ticks);
    release(&tickslock);
  }

  struct proc *p = myproc();   // get the currently running process
    80002550:	b7eff0ef          	jal	800018ce <myproc>
if(p && p->state == RUNNING){
    80002554:	c509                	beqz	a0,8000255e <clockintr+0x1c>
    80002556:	4d18                	lw	a4,24(a0)
    80002558:	4791                	li	a5,4
    8000255a:	04f70563          	beq	a4,a5,800025a4 <clockintr+0x62>
  asm volatile("csrr %0, time" : "=r" (x) );
    8000255e:	c01027f3          	rdtime	a5
}

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002562:	000f4737          	lui	a4,0xf4
    80002566:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    8000256a:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    8000256c:	14d79073          	csrw	stimecmp,a5
}
    80002570:	60e2                	ld	ra,24(sp)
    80002572:	6442                	ld	s0,16(sp)
    80002574:	6105                	addi	sp,sp,32
    80002576:	8082                	ret
    80002578:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    8000257a:	00014497          	auipc	s1,0x14
    8000257e:	87e48493          	addi	s1,s1,-1922 # 80015df8 <tickslock>
    80002582:	8526                	mv	a0,s1
    80002584:	e4afe0ef          	jal	80000bce <acquire>
    ticks++;
    80002588:	00005517          	auipc	a0,0x5
    8000258c:	34050513          	addi	a0,a0,832 # 800078c8 <ticks>
    80002590:	411c                	lw	a5,0(a0)
    80002592:	2785                	addiw	a5,a5,1
    80002594:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002596:	a3dff0ef          	jal	80001fd2 <wakeup>
    release(&tickslock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	ecafe0ef          	jal	80000c66 <release>
    800025a0:	64a2                	ld	s1,8(sp)
    800025a2:	b77d                	j	80002550 <clockintr+0xe>
    p->total_ticks++;   // add 1 tick to total ticks used by this process
    800025a4:	493c                	lw	a5,80(a0)
    800025a6:	2785                	addiw	a5,a5,1
    800025a8:	c93c                	sw	a5,80(a0)
    p->wait_time = 0;   // reset waiting time since it's running
    800025aa:	04052423          	sw	zero,72(a0)
    800025ae:	bf45                	j	8000255e <clockintr+0x1c>

00000000800025b0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800025b0:	1101                	addi	sp,sp,-32
    800025b2:	ec06                	sd	ra,24(sp)
    800025b4:	e822                	sd	s0,16(sp)
    800025b6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025b8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800025bc:	57fd                	li	a5,-1
    800025be:	17fe                	slli	a5,a5,0x3f
    800025c0:	07a5                	addi	a5,a5,9
    800025c2:	00f70c63          	beq	a4,a5,800025da <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800025c6:	57fd                	li	a5,-1
    800025c8:	17fe                	slli	a5,a5,0x3f
    800025ca:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800025cc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800025ce:	04f70763          	beq	a4,a5,8000261c <devintr+0x6c>
  }
}
    800025d2:	60e2                	ld	ra,24(sp)
    800025d4:	6442                	ld	s0,16(sp)
    800025d6:	6105                	addi	sp,sp,32
    800025d8:	8082                	ret
    800025da:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    800025dc:	701020ef          	jal	800054dc <plic_claim>
    800025e0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800025e2:	47a9                	li	a5,10
    800025e4:	00f50963          	beq	a0,a5,800025f6 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    800025e8:	4785                	li	a5,1
    800025ea:	00f50963          	beq	a0,a5,800025fc <devintr+0x4c>
    return 1;
    800025ee:	4505                	li	a0,1
    } else if(irq){
    800025f0:	e889                	bnez	s1,80002602 <devintr+0x52>
    800025f2:	64a2                	ld	s1,8(sp)
    800025f4:	bff9                	j	800025d2 <devintr+0x22>
      uartintr();
    800025f6:	bbafe0ef          	jal	800009b0 <uartintr>
    if(irq)
    800025fa:	a819                	j	80002610 <devintr+0x60>
      virtio_disk_intr();
    800025fc:	3a6030ef          	jal	800059a2 <virtio_disk_intr>
    if(irq)
    80002600:	a801                	j	80002610 <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    80002602:	85a6                	mv	a1,s1
    80002604:	00005517          	auipc	a0,0x5
    80002608:	c9450513          	addi	a0,a0,-876 # 80007298 <etext+0x298>
    8000260c:	eeffd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    80002610:	8526                	mv	a0,s1
    80002612:	6eb020ef          	jal	800054fc <plic_complete>
    return 1;
    80002616:	4505                	li	a0,1
    80002618:	64a2                	ld	s1,8(sp)
    8000261a:	bf65                	j	800025d2 <devintr+0x22>
    clockintr();
    8000261c:	f27ff0ef          	jal	80002542 <clockintr>
    return 2;
    80002620:	4509                	li	a0,2
    80002622:	bf45                	j	800025d2 <devintr+0x22>

0000000080002624 <usertrap>:
{
    80002624:	1101                	addi	sp,sp,-32
    80002626:	ec06                	sd	ra,24(sp)
    80002628:	e822                	sd	s0,16(sp)
    8000262a:	e426                	sd	s1,8(sp)
    8000262c:	e04a                	sd	s2,0(sp)
    8000262e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002630:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002634:	1007f793          	andi	a5,a5,256
    80002638:	eba5                	bnez	a5,800026a8 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000263a:	00003797          	auipc	a5,0x3
    8000263e:	df678793          	addi	a5,a5,-522 # 80005430 <kernelvec>
    80002642:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002646:	a88ff0ef          	jal	800018ce <myproc>
    8000264a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000264c:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000264e:	14102773          	csrr	a4,sepc
    80002652:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002654:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002658:	47a1                	li	a5,8
    8000265a:	04f70d63          	beq	a4,a5,800026b4 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    8000265e:	f53ff0ef          	jal	800025b0 <devintr>
    80002662:	892a                	mv	s2,a0
    80002664:	e945                	bnez	a0,80002714 <usertrap+0xf0>
    80002666:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000266a:	47bd                	li	a5,15
    8000266c:	08f70863          	beq	a4,a5,800026fc <usertrap+0xd8>
    80002670:	14202773          	csrr	a4,scause
    80002674:	47b5                	li	a5,13
    80002676:	08f70363          	beq	a4,a5,800026fc <usertrap+0xd8>
    8000267a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    8000267e:	5890                	lw	a2,48(s1)
    80002680:	00005517          	auipc	a0,0x5
    80002684:	c5850513          	addi	a0,a0,-936 # 800072d8 <etext+0x2d8>
    80002688:	e73fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000268c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002690:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002694:	00005517          	auipc	a0,0x5
    80002698:	c7450513          	addi	a0,a0,-908 # 80007308 <etext+0x308>
    8000269c:	e5ffd0ef          	jal	800004fa <printf>
    setkilled(p);
    800026a0:	8526                	mv	a0,s1
    800026a2:	b01ff0ef          	jal	800021a2 <setkilled>
    800026a6:	a035                	j	800026d2 <usertrap+0xae>
    panic("usertrap: not from user mode");
    800026a8:	00005517          	auipc	a0,0x5
    800026ac:	c1050513          	addi	a0,a0,-1008 # 800072b8 <etext+0x2b8>
    800026b0:	930fe0ef          	jal	800007e0 <panic>
    if(killed(p))
    800026b4:	b13ff0ef          	jal	800021c6 <killed>
    800026b8:	ed15                	bnez	a0,800026f4 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800026ba:	78b8                	ld	a4,112(s1)
    800026bc:	6f1c                	ld	a5,24(a4)
    800026be:	0791                	addi	a5,a5,4
    800026c0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800026c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ca:	10079073          	csrw	sstatus,a5
    syscall();
    800026ce:	246000ef          	jal	80002914 <syscall>
  if(killed(p))
    800026d2:	8526                	mv	a0,s1
    800026d4:	af3ff0ef          	jal	800021c6 <killed>
    800026d8:	e139                	bnez	a0,8000271e <usertrap+0xfa>
  prepare_return();
    800026da:	defff0ef          	jal	800024c8 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800026de:	74a8                	ld	a0,104(s1)
    800026e0:	8131                	srli	a0,a0,0xc
    800026e2:	57fd                	li	a5,-1
    800026e4:	17fe                	slli	a5,a5,0x3f
    800026e6:	8d5d                	or	a0,a0,a5
}
    800026e8:	60e2                	ld	ra,24(sp)
    800026ea:	6442                	ld	s0,16(sp)
    800026ec:	64a2                	ld	s1,8(sp)
    800026ee:	6902                	ld	s2,0(sp)
    800026f0:	6105                	addi	sp,sp,32
    800026f2:	8082                	ret
      kexit(-1);
    800026f4:	557d                	li	a0,-1
    800026f6:	9a5ff0ef          	jal	8000209a <kexit>
    800026fa:	b7c1                	j	800026ba <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800026fc:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002700:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002704:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    80002706:	00163613          	seqz	a2,a2
    8000270a:	74a8                	ld	a0,104(s1)
    8000270c:	e55fe0ef          	jal	80001560 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002710:	f169                	bnez	a0,800026d2 <usertrap+0xae>
    80002712:	b7a5                	j	8000267a <usertrap+0x56>
  if(killed(p))
    80002714:	8526                	mv	a0,s1
    80002716:	ab1ff0ef          	jal	800021c6 <killed>
    8000271a:	c511                	beqz	a0,80002726 <usertrap+0x102>
    8000271c:	a011                	j	80002720 <usertrap+0xfc>
    8000271e:	4901                	li	s2,0
    kexit(-1);
    80002720:	557d                	li	a0,-1
    80002722:	979ff0ef          	jal	8000209a <kexit>
  if(which_dev == 2)
    80002726:	4789                	li	a5,2
    80002728:	faf919e3          	bne	s2,a5,800026da <usertrap+0xb6>
    yield();
    8000272c:	82fff0ef          	jal	80001f5a <yield>
    80002730:	b76d                	j	800026da <usertrap+0xb6>

0000000080002732 <kerneltrap>:
{
    80002732:	7179                	addi	sp,sp,-48
    80002734:	f406                	sd	ra,40(sp)
    80002736:	f022                	sd	s0,32(sp)
    80002738:	ec26                	sd	s1,24(sp)
    8000273a:	e84a                	sd	s2,16(sp)
    8000273c:	e44e                	sd	s3,8(sp)
    8000273e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002740:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002744:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002748:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000274c:	1004f793          	andi	a5,s1,256
    80002750:	c795                	beqz	a5,8000277c <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002752:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002756:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002758:	eb85                	bnez	a5,80002788 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    8000275a:	e57ff0ef          	jal	800025b0 <devintr>
    8000275e:	c91d                	beqz	a0,80002794 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    80002760:	4789                	li	a5,2
    80002762:	04f50a63          	beq	a0,a5,800027b6 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002766:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000276a:	10049073          	csrw	sstatus,s1
}
    8000276e:	70a2                	ld	ra,40(sp)
    80002770:	7402                	ld	s0,32(sp)
    80002772:	64e2                	ld	s1,24(sp)
    80002774:	6942                	ld	s2,16(sp)
    80002776:	69a2                	ld	s3,8(sp)
    80002778:	6145                	addi	sp,sp,48
    8000277a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000277c:	00005517          	auipc	a0,0x5
    80002780:	bb450513          	addi	a0,a0,-1100 # 80007330 <etext+0x330>
    80002784:	85cfe0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002788:	00005517          	auipc	a0,0x5
    8000278c:	bd050513          	addi	a0,a0,-1072 # 80007358 <etext+0x358>
    80002790:	850fe0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002794:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002798:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    8000279c:	85ce                	mv	a1,s3
    8000279e:	00005517          	auipc	a0,0x5
    800027a2:	bda50513          	addi	a0,a0,-1062 # 80007378 <etext+0x378>
    800027a6:	d55fd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    800027aa:	00005517          	auipc	a0,0x5
    800027ae:	bf650513          	addi	a0,a0,-1034 # 800073a0 <etext+0x3a0>
    800027b2:	82efe0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0)
    800027b6:	918ff0ef          	jal	800018ce <myproc>
    800027ba:	d555                	beqz	a0,80002766 <kerneltrap+0x34>
    yield();
    800027bc:	f9eff0ef          	jal	80001f5a <yield>
    800027c0:	b75d                	j	80002766 <kerneltrap+0x34>

00000000800027c2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800027c2:	1101                	addi	sp,sp,-32
    800027c4:	ec06                	sd	ra,24(sp)
    800027c6:	e822                	sd	s0,16(sp)
    800027c8:	e426                	sd	s1,8(sp)
    800027ca:	1000                	addi	s0,sp,32
    800027cc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800027ce:	900ff0ef          	jal	800018ce <myproc>
  switch (n) {
    800027d2:	4795                	li	a5,5
    800027d4:	0497e163          	bltu	a5,s1,80002816 <argraw+0x54>
    800027d8:	048a                	slli	s1,s1,0x2
    800027da:	00005717          	auipc	a4,0x5
    800027de:	fd670713          	addi	a4,a4,-42 # 800077b0 <states.0+0x30>
    800027e2:	94ba                	add	s1,s1,a4
    800027e4:	409c                	lw	a5,0(s1)
    800027e6:	97ba                	add	a5,a5,a4
    800027e8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800027ea:	793c                	ld	a5,112(a0)
    800027ec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800027ee:	60e2                	ld	ra,24(sp)
    800027f0:	6442                	ld	s0,16(sp)
    800027f2:	64a2                	ld	s1,8(sp)
    800027f4:	6105                	addi	sp,sp,32
    800027f6:	8082                	ret
    return p->trapframe->a1;
    800027f8:	793c                	ld	a5,112(a0)
    800027fa:	7fa8                	ld	a0,120(a5)
    800027fc:	bfcd                	j	800027ee <argraw+0x2c>
    return p->trapframe->a2;
    800027fe:	793c                	ld	a5,112(a0)
    80002800:	63c8                	ld	a0,128(a5)
    80002802:	b7f5                	j	800027ee <argraw+0x2c>
    return p->trapframe->a3;
    80002804:	793c                	ld	a5,112(a0)
    80002806:	67c8                	ld	a0,136(a5)
    80002808:	b7dd                	j	800027ee <argraw+0x2c>
    return p->trapframe->a4;
    8000280a:	793c                	ld	a5,112(a0)
    8000280c:	6bc8                	ld	a0,144(a5)
    8000280e:	b7c5                	j	800027ee <argraw+0x2c>
    return p->trapframe->a5;
    80002810:	793c                	ld	a5,112(a0)
    80002812:	6fc8                	ld	a0,152(a5)
    80002814:	bfe9                	j	800027ee <argraw+0x2c>
  panic("argraw");
    80002816:	00005517          	auipc	a0,0x5
    8000281a:	b9a50513          	addi	a0,a0,-1126 # 800073b0 <etext+0x3b0>
    8000281e:	fc3fd0ef          	jal	800007e0 <panic>

0000000080002822 <fetchaddr>:
{
    80002822:	1101                	addi	sp,sp,-32
    80002824:	ec06                	sd	ra,24(sp)
    80002826:	e822                	sd	s0,16(sp)
    80002828:	e426                	sd	s1,8(sp)
    8000282a:	e04a                	sd	s2,0(sp)
    8000282c:	1000                	addi	s0,sp,32
    8000282e:	84aa                	mv	s1,a0
    80002830:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002832:	89cff0ef          	jal	800018ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002836:	713c                	ld	a5,96(a0)
    80002838:	02f4f663          	bgeu	s1,a5,80002864 <fetchaddr+0x42>
    8000283c:	00848713          	addi	a4,s1,8
    80002840:	02e7e463          	bltu	a5,a4,80002868 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002844:	46a1                	li	a3,8
    80002846:	8626                	mv	a2,s1
    80002848:	85ca                	mv	a1,s2
    8000284a:	7528                	ld	a0,104(a0)
    8000284c:	e7bfe0ef          	jal	800016c6 <copyin>
    80002850:	00a03533          	snez	a0,a0
    80002854:	40a00533          	neg	a0,a0
}
    80002858:	60e2                	ld	ra,24(sp)
    8000285a:	6442                	ld	s0,16(sp)
    8000285c:	64a2                	ld	s1,8(sp)
    8000285e:	6902                	ld	s2,0(sp)
    80002860:	6105                	addi	sp,sp,32
    80002862:	8082                	ret
    return -1;
    80002864:	557d                	li	a0,-1
    80002866:	bfcd                	j	80002858 <fetchaddr+0x36>
    80002868:	557d                	li	a0,-1
    8000286a:	b7fd                	j	80002858 <fetchaddr+0x36>

000000008000286c <fetchstr>:
{
    8000286c:	7179                	addi	sp,sp,-48
    8000286e:	f406                	sd	ra,40(sp)
    80002870:	f022                	sd	s0,32(sp)
    80002872:	ec26                	sd	s1,24(sp)
    80002874:	e84a                	sd	s2,16(sp)
    80002876:	e44e                	sd	s3,8(sp)
    80002878:	1800                	addi	s0,sp,48
    8000287a:	892a                	mv	s2,a0
    8000287c:	84ae                	mv	s1,a1
    8000287e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002880:	84eff0ef          	jal	800018ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002884:	86ce                	mv	a3,s3
    80002886:	864a                	mv	a2,s2
    80002888:	85a6                	mv	a1,s1
    8000288a:	7528                	ld	a0,104(a0)
    8000288c:	bfdfe0ef          	jal	80001488 <copyinstr>
    80002890:	00054c63          	bltz	a0,800028a8 <fetchstr+0x3c>
  return strlen(buf);
    80002894:	8526                	mv	a0,s1
    80002896:	d7cfe0ef          	jal	80000e12 <strlen>
}
    8000289a:	70a2                	ld	ra,40(sp)
    8000289c:	7402                	ld	s0,32(sp)
    8000289e:	64e2                	ld	s1,24(sp)
    800028a0:	6942                	ld	s2,16(sp)
    800028a2:	69a2                	ld	s3,8(sp)
    800028a4:	6145                	addi	sp,sp,48
    800028a6:	8082                	ret
    return -1;
    800028a8:	557d                	li	a0,-1
    800028aa:	bfc5                	j	8000289a <fetchstr+0x2e>

00000000800028ac <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800028ac:	1101                	addi	sp,sp,-32
    800028ae:	ec06                	sd	ra,24(sp)
    800028b0:	e822                	sd	s0,16(sp)
    800028b2:	e426                	sd	s1,8(sp)
    800028b4:	1000                	addi	s0,sp,32
    800028b6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800028b8:	f0bff0ef          	jal	800027c2 <argraw>
    800028bc:	c088                	sw	a0,0(s1)
}
    800028be:	60e2                	ld	ra,24(sp)
    800028c0:	6442                	ld	s0,16(sp)
    800028c2:	64a2                	ld	s1,8(sp)
    800028c4:	6105                	addi	sp,sp,32
    800028c6:	8082                	ret

00000000800028c8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800028c8:	1101                	addi	sp,sp,-32
    800028ca:	ec06                	sd	ra,24(sp)
    800028cc:	e822                	sd	s0,16(sp)
    800028ce:	e426                	sd	s1,8(sp)
    800028d0:	1000                	addi	s0,sp,32
    800028d2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800028d4:	eefff0ef          	jal	800027c2 <argraw>
    800028d8:	e088                	sd	a0,0(s1)
}
    800028da:	60e2                	ld	ra,24(sp)
    800028dc:	6442                	ld	s0,16(sp)
    800028de:	64a2                	ld	s1,8(sp)
    800028e0:	6105                	addi	sp,sp,32
    800028e2:	8082                	ret

00000000800028e4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800028e4:	7179                	addi	sp,sp,-48
    800028e6:	f406                	sd	ra,40(sp)
    800028e8:	f022                	sd	s0,32(sp)
    800028ea:	ec26                	sd	s1,24(sp)
    800028ec:	e84a                	sd	s2,16(sp)
    800028ee:	1800                	addi	s0,sp,48
    800028f0:	84ae                	mv	s1,a1
    800028f2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800028f4:	fd840593          	addi	a1,s0,-40
    800028f8:	fd1ff0ef          	jal	800028c8 <argaddr>
  return fetchstr(addr, buf, max);
    800028fc:	864a                	mv	a2,s2
    800028fe:	85a6                	mv	a1,s1
    80002900:	fd843503          	ld	a0,-40(s0)
    80002904:	f69ff0ef          	jal	8000286c <fetchstr>
}
    80002908:	70a2                	ld	ra,40(sp)
    8000290a:	7402                	ld	s0,32(sp)
    8000290c:	64e2                	ld	s1,24(sp)
    8000290e:	6942                	ld	s2,16(sp)
    80002910:	6145                	addi	sp,sp,48
    80002912:	8082                	ret

0000000080002914 <syscall>:

};

void
syscall(void)
{
    80002914:	1101                	addi	sp,sp,-32
    80002916:	ec06                	sd	ra,24(sp)
    80002918:	e822                	sd	s0,16(sp)
    8000291a:	e426                	sd	s1,8(sp)
    8000291c:	e04a                	sd	s2,0(sp)
    8000291e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002920:	faffe0ef          	jal	800018ce <myproc>
    80002924:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002926:	07053903          	ld	s2,112(a0)
    8000292a:	0a893783          	ld	a5,168(s2)
    8000292e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002932:	37fd                	addiw	a5,a5,-1
    80002934:	4759                	li	a4,22
    80002936:	00f76f63          	bltu	a4,a5,80002954 <syscall+0x40>
    8000293a:	00369713          	slli	a4,a3,0x3
    8000293e:	00005797          	auipc	a5,0x5
    80002942:	e8a78793          	addi	a5,a5,-374 # 800077c8 <syscalls>
    80002946:	97ba                	add	a5,a5,a4
    80002948:	639c                	ld	a5,0(a5)
    8000294a:	c789                	beqz	a5,80002954 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    8000294c:	9782                	jalr	a5
    8000294e:	06a93823          	sd	a0,112(s2)
    80002952:	a829                	j	8000296c <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002954:	17048613          	addi	a2,s1,368
    80002958:	588c                	lw	a1,48(s1)
    8000295a:	00005517          	auipc	a0,0x5
    8000295e:	a5e50513          	addi	a0,a0,-1442 # 800073b8 <etext+0x3b8>
    80002962:	b99fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002966:	78bc                	ld	a5,112(s1)
    80002968:	577d                	li	a4,-1
    8000296a:	fbb8                	sd	a4,112(a5)
  }
}
    8000296c:	60e2                	ld	ra,24(sp)
    8000296e:	6442                	ld	s0,16(sp)
    80002970:	64a2                	ld	s1,8(sp)
    80002972:	6902                	ld	s2,0(sp)
    80002974:	6105                	addi	sp,sp,32
    80002976:	8082                	ret

0000000080002978 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    80002978:	1101                	addi	sp,sp,-32
    8000297a:	ec06                	sd	ra,24(sp)
    8000297c:	e822                	sd	s0,16(sp)
    8000297e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002980:	fec40593          	addi	a1,s0,-20
    80002984:	4501                	li	a0,0
    80002986:	f27ff0ef          	jal	800028ac <argint>
  kexit(n);
    8000298a:	fec42503          	lw	a0,-20(s0)
    8000298e:	f0cff0ef          	jal	8000209a <kexit>
  return 0;  // not reached
}
    80002992:	4501                	li	a0,0
    80002994:	60e2                	ld	ra,24(sp)
    80002996:	6442                	ld	s0,16(sp)
    80002998:	6105                	addi	sp,sp,32
    8000299a:	8082                	ret

000000008000299c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000299c:	1141                	addi	sp,sp,-16
    8000299e:	e406                	sd	ra,8(sp)
    800029a0:	e022                	sd	s0,0(sp)
    800029a2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800029a4:	f2bfe0ef          	jal	800018ce <myproc>
}
    800029a8:	5908                	lw	a0,48(a0)
    800029aa:	60a2                	ld	ra,8(sp)
    800029ac:	6402                	ld	s0,0(sp)
    800029ae:	0141                	addi	sp,sp,16
    800029b0:	8082                	ret

00000000800029b2 <sys_fork>:

uint64
sys_fork(void)
{
    800029b2:	1141                	addi	sp,sp,-16
    800029b4:	e406                	sd	ra,8(sp)
    800029b6:	e022                	sd	s0,0(sp)
    800029b8:	0800                	addi	s0,sp,16
  return kfork();
    800029ba:	a7aff0ef          	jal	80001c34 <kfork>
}
    800029be:	60a2                	ld	ra,8(sp)
    800029c0:	6402                	ld	s0,0(sp)
    800029c2:	0141                	addi	sp,sp,16
    800029c4:	8082                	ret

00000000800029c6 <sys_wait>:

uint64
sys_wait(void)
{
    800029c6:	1101                	addi	sp,sp,-32
    800029c8:	ec06                	sd	ra,24(sp)
    800029ca:	e822                	sd	s0,16(sp)
    800029cc:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800029ce:	fe840593          	addi	a1,s0,-24
    800029d2:	4501                	li	a0,0
    800029d4:	ef5ff0ef          	jal	800028c8 <argaddr>
  return kwait(p);
    800029d8:	fe843503          	ld	a0,-24(s0)
    800029dc:	815ff0ef          	jal	800021f0 <kwait>
}
    800029e0:	60e2                	ld	ra,24(sp)
    800029e2:	6442                	ld	s0,16(sp)
    800029e4:	6105                	addi	sp,sp,32
    800029e6:	8082                	ret

00000000800029e8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800029e8:	7179                	addi	sp,sp,-48
    800029ea:	f406                	sd	ra,40(sp)
    800029ec:	f022                	sd	s0,32(sp)
    800029ee:	ec26                	sd	s1,24(sp)
    800029f0:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    800029f2:	fd840593          	addi	a1,s0,-40
    800029f6:	4501                	li	a0,0
    800029f8:	eb5ff0ef          	jal	800028ac <argint>
  argint(1, &t);
    800029fc:	fdc40593          	addi	a1,s0,-36
    80002a00:	4505                	li	a0,1
    80002a02:	eabff0ef          	jal	800028ac <argint>
  addr = myproc()->sz;
    80002a06:	ec9fe0ef          	jal	800018ce <myproc>
    80002a0a:	7124                	ld	s1,96(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002a0c:	fdc42703          	lw	a4,-36(s0)
    80002a10:	4785                	li	a5,1
    80002a12:	02f70163          	beq	a4,a5,80002a34 <sys_sbrk+0x4c>
    80002a16:	fd842783          	lw	a5,-40(s0)
    80002a1a:	0007cd63          	bltz	a5,80002a34 <sys_sbrk+0x4c>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002a1e:	97a6                	add	a5,a5,s1
    80002a20:	0297e863          	bltu	a5,s1,80002a50 <sys_sbrk+0x68>
      return -1;
    myproc()->sz += n;
    80002a24:	eabfe0ef          	jal	800018ce <myproc>
    80002a28:	fd842703          	lw	a4,-40(s0)
    80002a2c:	713c                	ld	a5,96(a0)
    80002a2e:	97ba                	add	a5,a5,a4
    80002a30:	f13c                	sd	a5,96(a0)
    80002a32:	a039                	j	80002a40 <sys_sbrk+0x58>
    if(growproc(n) < 0) {
    80002a34:	fd842503          	lw	a0,-40(s0)
    80002a38:	9acff0ef          	jal	80001be4 <growproc>
    80002a3c:	00054863          	bltz	a0,80002a4c <sys_sbrk+0x64>
  }
  return addr;
}
    80002a40:	8526                	mv	a0,s1
    80002a42:	70a2                	ld	ra,40(sp)
    80002a44:	7402                	ld	s0,32(sp)
    80002a46:	64e2                	ld	s1,24(sp)
    80002a48:	6145                	addi	sp,sp,48
    80002a4a:	8082                	ret
      return -1;
    80002a4c:	54fd                	li	s1,-1
    80002a4e:	bfcd                	j	80002a40 <sys_sbrk+0x58>
      return -1;
    80002a50:	54fd                	li	s1,-1
    80002a52:	b7fd                	j	80002a40 <sys_sbrk+0x58>

0000000080002a54 <sys_pause>:

uint64
sys_pause(void)
{
    80002a54:	7139                	addi	sp,sp,-64
    80002a56:	fc06                	sd	ra,56(sp)
    80002a58:	f822                	sd	s0,48(sp)
    80002a5a:	f04a                	sd	s2,32(sp)
    80002a5c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002a5e:	fcc40593          	addi	a1,s0,-52
    80002a62:	4501                	li	a0,0
    80002a64:	e49ff0ef          	jal	800028ac <argint>
  if(n < 0)
    80002a68:	fcc42783          	lw	a5,-52(s0)
    80002a6c:	0607c763          	bltz	a5,80002ada <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002a70:	00013517          	auipc	a0,0x13
    80002a74:	38850513          	addi	a0,a0,904 # 80015df8 <tickslock>
    80002a78:	956fe0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80002a7c:	00005917          	auipc	s2,0x5
    80002a80:	e4c92903          	lw	s2,-436(s2) # 800078c8 <ticks>
  while(ticks - ticks0 < n){
    80002a84:	fcc42783          	lw	a5,-52(s0)
    80002a88:	cf8d                	beqz	a5,80002ac2 <sys_pause+0x6e>
    80002a8a:	f426                	sd	s1,40(sp)
    80002a8c:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002a8e:	00013997          	auipc	s3,0x13
    80002a92:	36a98993          	addi	s3,s3,874 # 80015df8 <tickslock>
    80002a96:	00005497          	auipc	s1,0x5
    80002a9a:	e3248493          	addi	s1,s1,-462 # 800078c8 <ticks>
    if(killed(myproc())){
    80002a9e:	e31fe0ef          	jal	800018ce <myproc>
    80002aa2:	f24ff0ef          	jal	800021c6 <killed>
    80002aa6:	ed0d                	bnez	a0,80002ae0 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002aa8:	85ce                	mv	a1,s3
    80002aaa:	8526                	mv	a0,s1
    80002aac:	cdaff0ef          	jal	80001f86 <sleep>
  while(ticks - ticks0 < n){
    80002ab0:	409c                	lw	a5,0(s1)
    80002ab2:	412787bb          	subw	a5,a5,s2
    80002ab6:	fcc42703          	lw	a4,-52(s0)
    80002aba:	fee7e2e3          	bltu	a5,a4,80002a9e <sys_pause+0x4a>
    80002abe:	74a2                	ld	s1,40(sp)
    80002ac0:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002ac2:	00013517          	auipc	a0,0x13
    80002ac6:	33650513          	addi	a0,a0,822 # 80015df8 <tickslock>
    80002aca:	99cfe0ef          	jal	80000c66 <release>
  return 0;
    80002ace:	4501                	li	a0,0
}
    80002ad0:	70e2                	ld	ra,56(sp)
    80002ad2:	7442                	ld	s0,48(sp)
    80002ad4:	7902                	ld	s2,32(sp)
    80002ad6:	6121                	addi	sp,sp,64
    80002ad8:	8082                	ret
    n = 0;
    80002ada:	fc042623          	sw	zero,-52(s0)
    80002ade:	bf49                	j	80002a70 <sys_pause+0x1c>
      release(&tickslock);
    80002ae0:	00013517          	auipc	a0,0x13
    80002ae4:	31850513          	addi	a0,a0,792 # 80015df8 <tickslock>
    80002ae8:	97efe0ef          	jal	80000c66 <release>
      return -1;
    80002aec:	557d                	li	a0,-1
    80002aee:	74a2                	ld	s1,40(sp)
    80002af0:	69e2                	ld	s3,24(sp)
    80002af2:	bff9                	j	80002ad0 <sys_pause+0x7c>

0000000080002af4 <sys_kill>:

uint64
sys_kill(void)
{
    80002af4:	1101                	addi	sp,sp,-32
    80002af6:	ec06                	sd	ra,24(sp)
    80002af8:	e822                	sd	s0,16(sp)
    80002afa:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002afc:	fec40593          	addi	a1,s0,-20
    80002b00:	4501                	li	a0,0
    80002b02:	dabff0ef          	jal	800028ac <argint>
  return kkill(pid);
    80002b06:	fec42503          	lw	a0,-20(s0)
    80002b0a:	e32ff0ef          	jal	8000213c <kkill>
}
    80002b0e:	60e2                	ld	ra,24(sp)
    80002b10:	6442                	ld	s0,16(sp)
    80002b12:	6105                	addi	sp,sp,32
    80002b14:	8082                	ret

0000000080002b16 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002b20:	00013517          	auipc	a0,0x13
    80002b24:	2d850513          	addi	a0,a0,728 # 80015df8 <tickslock>
    80002b28:	8a6fe0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80002b2c:	00005497          	auipc	s1,0x5
    80002b30:	d9c4a483          	lw	s1,-612(s1) # 800078c8 <ticks>
  release(&tickslock);
    80002b34:	00013517          	auipc	a0,0x13
    80002b38:	2c450513          	addi	a0,a0,708 # 80015df8 <tickslock>
    80002b3c:	92afe0ef          	jal	80000c66 <release>
  return xticks;
}
    80002b40:	02049513          	slli	a0,s1,0x20
    80002b44:	9101                	srli	a0,a0,0x20
    80002b46:	60e2                	ld	ra,24(sp)
    80002b48:	6442                	ld	s0,16(sp)
    80002b4a:	64a2                	ld	s1,8(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret

0000000080002b50 <sys_getlev>:

uint64
sys_getlev(void)
{
    80002b50:	1141                	addi	sp,sp,-16
    80002b52:	e406                	sd	ra,8(sp)
    80002b54:	e022                	sd	s0,0(sp)
    80002b56:	0800                	addi	s0,sp,16
    struct proc *p = myproc();
    80002b58:	d77fe0ef          	jal	800018ce <myproc>
    return p->queue_level;  // return current queue level
}
    80002b5c:	4128                	lw	a0,64(a0)
    80002b5e:	60a2                	ld	ra,8(sp)
    80002b60:	6402                	ld	s0,0(sp)
    80002b62:	0141                	addi	sp,sp,16
    80002b64:	8082                	ret

0000000080002b66 <sys_getpinfo>:

uint64
sys_getpinfo(void)
{
    80002b66:	1141                	addi	sp,sp,-16
    80002b68:	e406                	sd	ra,8(sp)
    80002b6a:	e022                	sd	s0,0(sp)
    80002b6c:	0800                	addi	s0,sp,16
    struct proc *p = myproc();
    80002b6e:	d61fe0ef          	jal	800018ce <myproc>
    return p->total_ticks; // or you can make a struct to return multiple fields
}
    80002b72:	4928                	lw	a0,80(a0)
    80002b74:	60a2                	ld	ra,8(sp)
    80002b76:	6402                	ld	s0,0(sp)
    80002b78:	0141                	addi	sp,sp,16
    80002b7a:	8082                	ret

0000000080002b7c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002b7c:	7179                	addi	sp,sp,-48
    80002b7e:	f406                	sd	ra,40(sp)
    80002b80:	f022                	sd	s0,32(sp)
    80002b82:	ec26                	sd	s1,24(sp)
    80002b84:	e84a                	sd	s2,16(sp)
    80002b86:	e44e                	sd	s3,8(sp)
    80002b88:	e052                	sd	s4,0(sp)
    80002b8a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002b8c:	00005597          	auipc	a1,0x5
    80002b90:	84c58593          	addi	a1,a1,-1972 # 800073d8 <etext+0x3d8>
    80002b94:	00013517          	auipc	a0,0x13
    80002b98:	27c50513          	addi	a0,a0,636 # 80015e10 <bcache>
    80002b9c:	fb3fd0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ba0:	0001b797          	auipc	a5,0x1b
    80002ba4:	27078793          	addi	a5,a5,624 # 8001de10 <bcache+0x8000>
    80002ba8:	0001b717          	auipc	a4,0x1b
    80002bac:	4d070713          	addi	a4,a4,1232 # 8001e078 <bcache+0x8268>
    80002bb0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002bb4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002bb8:	00013497          	auipc	s1,0x13
    80002bbc:	27048493          	addi	s1,s1,624 # 80015e28 <bcache+0x18>
    b->next = bcache.head.next;
    80002bc0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002bc2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002bc4:	00005a17          	auipc	s4,0x5
    80002bc8:	81ca0a13          	addi	s4,s4,-2020 # 800073e0 <etext+0x3e0>
    b->next = bcache.head.next;
    80002bcc:	2b893783          	ld	a5,696(s2)
    80002bd0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002bd2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002bd6:	85d2                	mv	a1,s4
    80002bd8:	01048513          	addi	a0,s1,16
    80002bdc:	322010ef          	jal	80003efe <initsleeplock>
    bcache.head.next->prev = b;
    80002be0:	2b893783          	ld	a5,696(s2)
    80002be4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002be6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002bea:	45848493          	addi	s1,s1,1112
    80002bee:	fd349fe3          	bne	s1,s3,80002bcc <binit+0x50>
  }
}
    80002bf2:	70a2                	ld	ra,40(sp)
    80002bf4:	7402                	ld	s0,32(sp)
    80002bf6:	64e2                	ld	s1,24(sp)
    80002bf8:	6942                	ld	s2,16(sp)
    80002bfa:	69a2                	ld	s3,8(sp)
    80002bfc:	6a02                	ld	s4,0(sp)
    80002bfe:	6145                	addi	sp,sp,48
    80002c00:	8082                	ret

0000000080002c02 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002c02:	7179                	addi	sp,sp,-48
    80002c04:	f406                	sd	ra,40(sp)
    80002c06:	f022                	sd	s0,32(sp)
    80002c08:	ec26                	sd	s1,24(sp)
    80002c0a:	e84a                	sd	s2,16(sp)
    80002c0c:	e44e                	sd	s3,8(sp)
    80002c0e:	1800                	addi	s0,sp,48
    80002c10:	892a                	mv	s2,a0
    80002c12:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002c14:	00013517          	auipc	a0,0x13
    80002c18:	1fc50513          	addi	a0,a0,508 # 80015e10 <bcache>
    80002c1c:	fb3fd0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002c20:	0001b497          	auipc	s1,0x1b
    80002c24:	4a84b483          	ld	s1,1192(s1) # 8001e0c8 <bcache+0x82b8>
    80002c28:	0001b797          	auipc	a5,0x1b
    80002c2c:	45078793          	addi	a5,a5,1104 # 8001e078 <bcache+0x8268>
    80002c30:	02f48b63          	beq	s1,a5,80002c66 <bread+0x64>
    80002c34:	873e                	mv	a4,a5
    80002c36:	a021                	j	80002c3e <bread+0x3c>
    80002c38:	68a4                	ld	s1,80(s1)
    80002c3a:	02e48663          	beq	s1,a4,80002c66 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002c3e:	449c                	lw	a5,8(s1)
    80002c40:	ff279ce3          	bne	a5,s2,80002c38 <bread+0x36>
    80002c44:	44dc                	lw	a5,12(s1)
    80002c46:	ff3799e3          	bne	a5,s3,80002c38 <bread+0x36>
      b->refcnt++;
    80002c4a:	40bc                	lw	a5,64(s1)
    80002c4c:	2785                	addiw	a5,a5,1
    80002c4e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002c50:	00013517          	auipc	a0,0x13
    80002c54:	1c050513          	addi	a0,a0,448 # 80015e10 <bcache>
    80002c58:	80efe0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002c5c:	01048513          	addi	a0,s1,16
    80002c60:	2d4010ef          	jal	80003f34 <acquiresleep>
      return b;
    80002c64:	a889                	j	80002cb6 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002c66:	0001b497          	auipc	s1,0x1b
    80002c6a:	45a4b483          	ld	s1,1114(s1) # 8001e0c0 <bcache+0x82b0>
    80002c6e:	0001b797          	auipc	a5,0x1b
    80002c72:	40a78793          	addi	a5,a5,1034 # 8001e078 <bcache+0x8268>
    80002c76:	00f48863          	beq	s1,a5,80002c86 <bread+0x84>
    80002c7a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002c7c:	40bc                	lw	a5,64(s1)
    80002c7e:	cb91                	beqz	a5,80002c92 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002c80:	64a4                	ld	s1,72(s1)
    80002c82:	fee49de3          	bne	s1,a4,80002c7c <bread+0x7a>
  panic("bget: no buffers");
    80002c86:	00004517          	auipc	a0,0x4
    80002c8a:	76250513          	addi	a0,a0,1890 # 800073e8 <etext+0x3e8>
    80002c8e:	b53fd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80002c92:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002c96:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002c9a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002c9e:	4785                	li	a5,1
    80002ca0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ca2:	00013517          	auipc	a0,0x13
    80002ca6:	16e50513          	addi	a0,a0,366 # 80015e10 <bcache>
    80002caa:	fbdfd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002cae:	01048513          	addi	a0,s1,16
    80002cb2:	282010ef          	jal	80003f34 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002cb6:	409c                	lw	a5,0(s1)
    80002cb8:	cb89                	beqz	a5,80002cca <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002cba:	8526                	mv	a0,s1
    80002cbc:	70a2                	ld	ra,40(sp)
    80002cbe:	7402                	ld	s0,32(sp)
    80002cc0:	64e2                	ld	s1,24(sp)
    80002cc2:	6942                	ld	s2,16(sp)
    80002cc4:	69a2                	ld	s3,8(sp)
    80002cc6:	6145                	addi	sp,sp,48
    80002cc8:	8082                	ret
    virtio_disk_rw(b, 0);
    80002cca:	4581                	li	a1,0
    80002ccc:	8526                	mv	a0,s1
    80002cce:	2c3020ef          	jal	80005790 <virtio_disk_rw>
    b->valid = 1;
    80002cd2:	4785                	li	a5,1
    80002cd4:	c09c                	sw	a5,0(s1)
  return b;
    80002cd6:	b7d5                	j	80002cba <bread+0xb8>

0000000080002cd8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	e426                	sd	s1,8(sp)
    80002ce0:	1000                	addi	s0,sp,32
    80002ce2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ce4:	0541                	addi	a0,a0,16
    80002ce6:	2cc010ef          	jal	80003fb2 <holdingsleep>
    80002cea:	c911                	beqz	a0,80002cfe <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002cec:	4585                	li	a1,1
    80002cee:	8526                	mv	a0,s1
    80002cf0:	2a1020ef          	jal	80005790 <virtio_disk_rw>
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret
    panic("bwrite");
    80002cfe:	00004517          	auipc	a0,0x4
    80002d02:	70250513          	addi	a0,a0,1794 # 80007400 <etext+0x400>
    80002d06:	adbfd0ef          	jal	800007e0 <panic>

0000000080002d0a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002d0a:	1101                	addi	sp,sp,-32
    80002d0c:	ec06                	sd	ra,24(sp)
    80002d0e:	e822                	sd	s0,16(sp)
    80002d10:	e426                	sd	s1,8(sp)
    80002d12:	e04a                	sd	s2,0(sp)
    80002d14:	1000                	addi	s0,sp,32
    80002d16:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002d18:	01050913          	addi	s2,a0,16
    80002d1c:	854a                	mv	a0,s2
    80002d1e:	294010ef          	jal	80003fb2 <holdingsleep>
    80002d22:	c135                	beqz	a0,80002d86 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002d24:	854a                	mv	a0,s2
    80002d26:	254010ef          	jal	80003f7a <releasesleep>

  acquire(&bcache.lock);
    80002d2a:	00013517          	auipc	a0,0x13
    80002d2e:	0e650513          	addi	a0,a0,230 # 80015e10 <bcache>
    80002d32:	e9dfd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002d36:	40bc                	lw	a5,64(s1)
    80002d38:	37fd                	addiw	a5,a5,-1
    80002d3a:	0007871b          	sext.w	a4,a5
    80002d3e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002d40:	e71d                	bnez	a4,80002d6e <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002d42:	68b8                	ld	a4,80(s1)
    80002d44:	64bc                	ld	a5,72(s1)
    80002d46:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002d48:	68b8                	ld	a4,80(s1)
    80002d4a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002d4c:	0001b797          	auipc	a5,0x1b
    80002d50:	0c478793          	addi	a5,a5,196 # 8001de10 <bcache+0x8000>
    80002d54:	2b87b703          	ld	a4,696(a5)
    80002d58:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002d5a:	0001b717          	auipc	a4,0x1b
    80002d5e:	31e70713          	addi	a4,a4,798 # 8001e078 <bcache+0x8268>
    80002d62:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002d64:	2b87b703          	ld	a4,696(a5)
    80002d68:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002d6a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002d6e:	00013517          	auipc	a0,0x13
    80002d72:	0a250513          	addi	a0,a0,162 # 80015e10 <bcache>
    80002d76:	ef1fd0ef          	jal	80000c66 <release>
}
    80002d7a:	60e2                	ld	ra,24(sp)
    80002d7c:	6442                	ld	s0,16(sp)
    80002d7e:	64a2                	ld	s1,8(sp)
    80002d80:	6902                	ld	s2,0(sp)
    80002d82:	6105                	addi	sp,sp,32
    80002d84:	8082                	ret
    panic("brelse");
    80002d86:	00004517          	auipc	a0,0x4
    80002d8a:	68250513          	addi	a0,a0,1666 # 80007408 <etext+0x408>
    80002d8e:	a53fd0ef          	jal	800007e0 <panic>

0000000080002d92 <bpin>:

void
bpin(struct buf *b) {
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	e426                	sd	s1,8(sp)
    80002d9a:	1000                	addi	s0,sp,32
    80002d9c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d9e:	00013517          	auipc	a0,0x13
    80002da2:	07250513          	addi	a0,a0,114 # 80015e10 <bcache>
    80002da6:	e29fd0ef          	jal	80000bce <acquire>
  b->refcnt++;
    80002daa:	40bc                	lw	a5,64(s1)
    80002dac:	2785                	addiw	a5,a5,1
    80002dae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002db0:	00013517          	auipc	a0,0x13
    80002db4:	06050513          	addi	a0,a0,96 # 80015e10 <bcache>
    80002db8:	eaffd0ef          	jal	80000c66 <release>
}
    80002dbc:	60e2                	ld	ra,24(sp)
    80002dbe:	6442                	ld	s0,16(sp)
    80002dc0:	64a2                	ld	s1,8(sp)
    80002dc2:	6105                	addi	sp,sp,32
    80002dc4:	8082                	ret

0000000080002dc6 <bunpin>:

void
bunpin(struct buf *b) {
    80002dc6:	1101                	addi	sp,sp,-32
    80002dc8:	ec06                	sd	ra,24(sp)
    80002dca:	e822                	sd	s0,16(sp)
    80002dcc:	e426                	sd	s1,8(sp)
    80002dce:	1000                	addi	s0,sp,32
    80002dd0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002dd2:	00013517          	auipc	a0,0x13
    80002dd6:	03e50513          	addi	a0,a0,62 # 80015e10 <bcache>
    80002dda:	df5fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002dde:	40bc                	lw	a5,64(s1)
    80002de0:	37fd                	addiw	a5,a5,-1
    80002de2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002de4:	00013517          	auipc	a0,0x13
    80002de8:	02c50513          	addi	a0,a0,44 # 80015e10 <bcache>
    80002dec:	e7bfd0ef          	jal	80000c66 <release>
}
    80002df0:	60e2                	ld	ra,24(sp)
    80002df2:	6442                	ld	s0,16(sp)
    80002df4:	64a2                	ld	s1,8(sp)
    80002df6:	6105                	addi	sp,sp,32
    80002df8:	8082                	ret

0000000080002dfa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	e426                	sd	s1,8(sp)
    80002e02:	e04a                	sd	s2,0(sp)
    80002e04:	1000                	addi	s0,sp,32
    80002e06:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002e08:	00d5d59b          	srliw	a1,a1,0xd
    80002e0c:	0001b797          	auipc	a5,0x1b
    80002e10:	6e07a783          	lw	a5,1760(a5) # 8001e4ec <sb+0x1c>
    80002e14:	9dbd                	addw	a1,a1,a5
    80002e16:	dedff0ef          	jal	80002c02 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002e1a:	0074f713          	andi	a4,s1,7
    80002e1e:	4785                	li	a5,1
    80002e20:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002e24:	14ce                	slli	s1,s1,0x33
    80002e26:	90d9                	srli	s1,s1,0x36
    80002e28:	00950733          	add	a4,a0,s1
    80002e2c:	05874703          	lbu	a4,88(a4)
    80002e30:	00e7f6b3          	and	a3,a5,a4
    80002e34:	c29d                	beqz	a3,80002e5a <bfree+0x60>
    80002e36:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002e38:	94aa                	add	s1,s1,a0
    80002e3a:	fff7c793          	not	a5,a5
    80002e3e:	8f7d                	and	a4,a4,a5
    80002e40:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80002e44:	7f9000ef          	jal	80003e3c <log_write>
  brelse(bp);
    80002e48:	854a                	mv	a0,s2
    80002e4a:	ec1ff0ef          	jal	80002d0a <brelse>
}
    80002e4e:	60e2                	ld	ra,24(sp)
    80002e50:	6442                	ld	s0,16(sp)
    80002e52:	64a2                	ld	s1,8(sp)
    80002e54:	6902                	ld	s2,0(sp)
    80002e56:	6105                	addi	sp,sp,32
    80002e58:	8082                	ret
    panic("freeing free block");
    80002e5a:	00004517          	auipc	a0,0x4
    80002e5e:	5b650513          	addi	a0,a0,1462 # 80007410 <etext+0x410>
    80002e62:	97ffd0ef          	jal	800007e0 <panic>

0000000080002e66 <balloc>:
{
    80002e66:	711d                	addi	sp,sp,-96
    80002e68:	ec86                	sd	ra,88(sp)
    80002e6a:	e8a2                	sd	s0,80(sp)
    80002e6c:	e4a6                	sd	s1,72(sp)
    80002e6e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002e70:	0001b797          	auipc	a5,0x1b
    80002e74:	6647a783          	lw	a5,1636(a5) # 8001e4d4 <sb+0x4>
    80002e78:	0e078f63          	beqz	a5,80002f76 <balloc+0x110>
    80002e7c:	e0ca                	sd	s2,64(sp)
    80002e7e:	fc4e                	sd	s3,56(sp)
    80002e80:	f852                	sd	s4,48(sp)
    80002e82:	f456                	sd	s5,40(sp)
    80002e84:	f05a                	sd	s6,32(sp)
    80002e86:	ec5e                	sd	s7,24(sp)
    80002e88:	e862                	sd	s8,16(sp)
    80002e8a:	e466                	sd	s9,8(sp)
    80002e8c:	8baa                	mv	s7,a0
    80002e8e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002e90:	0001bb17          	auipc	s6,0x1b
    80002e94:	640b0b13          	addi	s6,s6,1600 # 8001e4d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e98:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002e9a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e9c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002e9e:	6c89                	lui	s9,0x2
    80002ea0:	a0b5                	j	80002f0c <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002ea2:	97ca                	add	a5,a5,s2
    80002ea4:	8e55                	or	a2,a2,a3
    80002ea6:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80002eaa:	854a                	mv	a0,s2
    80002eac:	791000ef          	jal	80003e3c <log_write>
        brelse(bp);
    80002eb0:	854a                	mv	a0,s2
    80002eb2:	e59ff0ef          	jal	80002d0a <brelse>
  bp = bread(dev, bno);
    80002eb6:	85a6                	mv	a1,s1
    80002eb8:	855e                	mv	a0,s7
    80002eba:	d49ff0ef          	jal	80002c02 <bread>
    80002ebe:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002ec0:	40000613          	li	a2,1024
    80002ec4:	4581                	li	a1,0
    80002ec6:	05850513          	addi	a0,a0,88
    80002eca:	dd9fd0ef          	jal	80000ca2 <memset>
  log_write(bp);
    80002ece:	854a                	mv	a0,s2
    80002ed0:	76d000ef          	jal	80003e3c <log_write>
  brelse(bp);
    80002ed4:	854a                	mv	a0,s2
    80002ed6:	e35ff0ef          	jal	80002d0a <brelse>
}
    80002eda:	6906                	ld	s2,64(sp)
    80002edc:	79e2                	ld	s3,56(sp)
    80002ede:	7a42                	ld	s4,48(sp)
    80002ee0:	7aa2                	ld	s5,40(sp)
    80002ee2:	7b02                	ld	s6,32(sp)
    80002ee4:	6be2                	ld	s7,24(sp)
    80002ee6:	6c42                	ld	s8,16(sp)
    80002ee8:	6ca2                	ld	s9,8(sp)
}
    80002eea:	8526                	mv	a0,s1
    80002eec:	60e6                	ld	ra,88(sp)
    80002eee:	6446                	ld	s0,80(sp)
    80002ef0:	64a6                	ld	s1,72(sp)
    80002ef2:	6125                	addi	sp,sp,96
    80002ef4:	8082                	ret
    brelse(bp);
    80002ef6:	854a                	mv	a0,s2
    80002ef8:	e13ff0ef          	jal	80002d0a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002efc:	015c87bb          	addw	a5,s9,s5
    80002f00:	00078a9b          	sext.w	s5,a5
    80002f04:	004b2703          	lw	a4,4(s6)
    80002f08:	04eaff63          	bgeu	s5,a4,80002f66 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    80002f0c:	41fad79b          	sraiw	a5,s5,0x1f
    80002f10:	0137d79b          	srliw	a5,a5,0x13
    80002f14:	015787bb          	addw	a5,a5,s5
    80002f18:	40d7d79b          	sraiw	a5,a5,0xd
    80002f1c:	01cb2583          	lw	a1,28(s6)
    80002f20:	9dbd                	addw	a1,a1,a5
    80002f22:	855e                	mv	a0,s7
    80002f24:	cdfff0ef          	jal	80002c02 <bread>
    80002f28:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f2a:	004b2503          	lw	a0,4(s6)
    80002f2e:	000a849b          	sext.w	s1,s5
    80002f32:	8762                	mv	a4,s8
    80002f34:	fca4f1e3          	bgeu	s1,a0,80002ef6 <balloc+0x90>
      m = 1 << (bi % 8);
    80002f38:	00777693          	andi	a3,a4,7
    80002f3c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002f40:	41f7579b          	sraiw	a5,a4,0x1f
    80002f44:	01d7d79b          	srliw	a5,a5,0x1d
    80002f48:	9fb9                	addw	a5,a5,a4
    80002f4a:	4037d79b          	sraiw	a5,a5,0x3
    80002f4e:	00f90633          	add	a2,s2,a5
    80002f52:	05864603          	lbu	a2,88(a2)
    80002f56:	00c6f5b3          	and	a1,a3,a2
    80002f5a:	d5a1                	beqz	a1,80002ea2 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f5c:	2705                	addiw	a4,a4,1
    80002f5e:	2485                	addiw	s1,s1,1
    80002f60:	fd471ae3          	bne	a4,s4,80002f34 <balloc+0xce>
    80002f64:	bf49                	j	80002ef6 <balloc+0x90>
    80002f66:	6906                	ld	s2,64(sp)
    80002f68:	79e2                	ld	s3,56(sp)
    80002f6a:	7a42                	ld	s4,48(sp)
    80002f6c:	7aa2                	ld	s5,40(sp)
    80002f6e:	7b02                	ld	s6,32(sp)
    80002f70:	6be2                	ld	s7,24(sp)
    80002f72:	6c42                	ld	s8,16(sp)
    80002f74:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80002f76:	00004517          	auipc	a0,0x4
    80002f7a:	4b250513          	addi	a0,a0,1202 # 80007428 <etext+0x428>
    80002f7e:	d7cfd0ef          	jal	800004fa <printf>
  return 0;
    80002f82:	4481                	li	s1,0
    80002f84:	b79d                	j	80002eea <balloc+0x84>

0000000080002f86 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002f86:	7179                	addi	sp,sp,-48
    80002f88:	f406                	sd	ra,40(sp)
    80002f8a:	f022                	sd	s0,32(sp)
    80002f8c:	ec26                	sd	s1,24(sp)
    80002f8e:	e84a                	sd	s2,16(sp)
    80002f90:	e44e                	sd	s3,8(sp)
    80002f92:	1800                	addi	s0,sp,48
    80002f94:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002f96:	47ad                	li	a5,11
    80002f98:	02b7e663          	bltu	a5,a1,80002fc4 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80002f9c:	02059793          	slli	a5,a1,0x20
    80002fa0:	01e7d593          	srli	a1,a5,0x1e
    80002fa4:	00b504b3          	add	s1,a0,a1
    80002fa8:	0504a903          	lw	s2,80(s1)
    80002fac:	06091a63          	bnez	s2,80003020 <bmap+0x9a>
      addr = balloc(ip->dev);
    80002fb0:	4108                	lw	a0,0(a0)
    80002fb2:	eb5ff0ef          	jal	80002e66 <balloc>
    80002fb6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002fba:	06090363          	beqz	s2,80003020 <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    80002fbe:	0524a823          	sw	s2,80(s1)
    80002fc2:	a8b9                	j	80003020 <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002fc4:	ff45849b          	addiw	s1,a1,-12
    80002fc8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002fcc:	0ff00793          	li	a5,255
    80002fd0:	06e7ee63          	bltu	a5,a4,8000304c <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002fd4:	08052903          	lw	s2,128(a0)
    80002fd8:	00091d63          	bnez	s2,80002ff2 <bmap+0x6c>
      addr = balloc(ip->dev);
    80002fdc:	4108                	lw	a0,0(a0)
    80002fde:	e89ff0ef          	jal	80002e66 <balloc>
    80002fe2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002fe6:	02090d63          	beqz	s2,80003020 <bmap+0x9a>
    80002fea:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002fec:	0929a023          	sw	s2,128(s3)
    80002ff0:	a011                	j	80002ff4 <bmap+0x6e>
    80002ff2:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80002ff4:	85ca                	mv	a1,s2
    80002ff6:	0009a503          	lw	a0,0(s3)
    80002ffa:	c09ff0ef          	jal	80002c02 <bread>
    80002ffe:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003000:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003004:	02049713          	slli	a4,s1,0x20
    80003008:	01e75593          	srli	a1,a4,0x1e
    8000300c:	00b784b3          	add	s1,a5,a1
    80003010:	0004a903          	lw	s2,0(s1)
    80003014:	00090e63          	beqz	s2,80003030 <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003018:	8552                	mv	a0,s4
    8000301a:	cf1ff0ef          	jal	80002d0a <brelse>
    return addr;
    8000301e:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003020:	854a                	mv	a0,s2
    80003022:	70a2                	ld	ra,40(sp)
    80003024:	7402                	ld	s0,32(sp)
    80003026:	64e2                	ld	s1,24(sp)
    80003028:	6942                	ld	s2,16(sp)
    8000302a:	69a2                	ld	s3,8(sp)
    8000302c:	6145                	addi	sp,sp,48
    8000302e:	8082                	ret
      addr = balloc(ip->dev);
    80003030:	0009a503          	lw	a0,0(s3)
    80003034:	e33ff0ef          	jal	80002e66 <balloc>
    80003038:	0005091b          	sext.w	s2,a0
      if(addr){
    8000303c:	fc090ee3          	beqz	s2,80003018 <bmap+0x92>
        a[bn] = addr;
    80003040:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003044:	8552                	mv	a0,s4
    80003046:	5f7000ef          	jal	80003e3c <log_write>
    8000304a:	b7f9                	j	80003018 <bmap+0x92>
    8000304c:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    8000304e:	00004517          	auipc	a0,0x4
    80003052:	3f250513          	addi	a0,a0,1010 # 80007440 <etext+0x440>
    80003056:	f8afd0ef          	jal	800007e0 <panic>

000000008000305a <iget>:
{
    8000305a:	7179                	addi	sp,sp,-48
    8000305c:	f406                	sd	ra,40(sp)
    8000305e:	f022                	sd	s0,32(sp)
    80003060:	ec26                	sd	s1,24(sp)
    80003062:	e84a                	sd	s2,16(sp)
    80003064:	e44e                	sd	s3,8(sp)
    80003066:	e052                	sd	s4,0(sp)
    80003068:	1800                	addi	s0,sp,48
    8000306a:	89aa                	mv	s3,a0
    8000306c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000306e:	0001b517          	auipc	a0,0x1b
    80003072:	48250513          	addi	a0,a0,1154 # 8001e4f0 <itable>
    80003076:	b59fd0ef          	jal	80000bce <acquire>
  empty = 0;
    8000307a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000307c:	0001b497          	auipc	s1,0x1b
    80003080:	48c48493          	addi	s1,s1,1164 # 8001e508 <itable+0x18>
    80003084:	0001d697          	auipc	a3,0x1d
    80003088:	f1468693          	addi	a3,a3,-236 # 8001ff98 <log>
    8000308c:	a039                	j	8000309a <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000308e:	02090963          	beqz	s2,800030c0 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003092:	08848493          	addi	s1,s1,136
    80003096:	02d48863          	beq	s1,a3,800030c6 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000309a:	449c                	lw	a5,8(s1)
    8000309c:	fef059e3          	blez	a5,8000308e <iget+0x34>
    800030a0:	4098                	lw	a4,0(s1)
    800030a2:	ff3716e3          	bne	a4,s3,8000308e <iget+0x34>
    800030a6:	40d8                	lw	a4,4(s1)
    800030a8:	ff4713e3          	bne	a4,s4,8000308e <iget+0x34>
      ip->ref++;
    800030ac:	2785                	addiw	a5,a5,1
    800030ae:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800030b0:	0001b517          	auipc	a0,0x1b
    800030b4:	44050513          	addi	a0,a0,1088 # 8001e4f0 <itable>
    800030b8:	baffd0ef          	jal	80000c66 <release>
      return ip;
    800030bc:	8926                	mv	s2,s1
    800030be:	a02d                	j	800030e8 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800030c0:	fbe9                	bnez	a5,80003092 <iget+0x38>
      empty = ip;
    800030c2:	8926                	mv	s2,s1
    800030c4:	b7f9                	j	80003092 <iget+0x38>
  if(empty == 0)
    800030c6:	02090a63          	beqz	s2,800030fa <iget+0xa0>
  ip->dev = dev;
    800030ca:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800030ce:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800030d2:	4785                	li	a5,1
    800030d4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800030d8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800030dc:	0001b517          	auipc	a0,0x1b
    800030e0:	41450513          	addi	a0,a0,1044 # 8001e4f0 <itable>
    800030e4:	b83fd0ef          	jal	80000c66 <release>
}
    800030e8:	854a                	mv	a0,s2
    800030ea:	70a2                	ld	ra,40(sp)
    800030ec:	7402                	ld	s0,32(sp)
    800030ee:	64e2                	ld	s1,24(sp)
    800030f0:	6942                	ld	s2,16(sp)
    800030f2:	69a2                	ld	s3,8(sp)
    800030f4:	6a02                	ld	s4,0(sp)
    800030f6:	6145                	addi	sp,sp,48
    800030f8:	8082                	ret
    panic("iget: no inodes");
    800030fa:	00004517          	auipc	a0,0x4
    800030fe:	35e50513          	addi	a0,a0,862 # 80007458 <etext+0x458>
    80003102:	edefd0ef          	jal	800007e0 <panic>

0000000080003106 <iinit>:
{
    80003106:	7179                	addi	sp,sp,-48
    80003108:	f406                	sd	ra,40(sp)
    8000310a:	f022                	sd	s0,32(sp)
    8000310c:	ec26                	sd	s1,24(sp)
    8000310e:	e84a                	sd	s2,16(sp)
    80003110:	e44e                	sd	s3,8(sp)
    80003112:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003114:	00004597          	auipc	a1,0x4
    80003118:	35458593          	addi	a1,a1,852 # 80007468 <etext+0x468>
    8000311c:	0001b517          	auipc	a0,0x1b
    80003120:	3d450513          	addi	a0,a0,980 # 8001e4f0 <itable>
    80003124:	a2bfd0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003128:	0001b497          	auipc	s1,0x1b
    8000312c:	3f048493          	addi	s1,s1,1008 # 8001e518 <itable+0x28>
    80003130:	0001d997          	auipc	s3,0x1d
    80003134:	e7898993          	addi	s3,s3,-392 # 8001ffa8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003138:	00004917          	auipc	s2,0x4
    8000313c:	33890913          	addi	s2,s2,824 # 80007470 <etext+0x470>
    80003140:	85ca                	mv	a1,s2
    80003142:	8526                	mv	a0,s1
    80003144:	5bb000ef          	jal	80003efe <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003148:	08848493          	addi	s1,s1,136
    8000314c:	ff349ae3          	bne	s1,s3,80003140 <iinit+0x3a>
}
    80003150:	70a2                	ld	ra,40(sp)
    80003152:	7402                	ld	s0,32(sp)
    80003154:	64e2                	ld	s1,24(sp)
    80003156:	6942                	ld	s2,16(sp)
    80003158:	69a2                	ld	s3,8(sp)
    8000315a:	6145                	addi	sp,sp,48
    8000315c:	8082                	ret

000000008000315e <ialloc>:
{
    8000315e:	7139                	addi	sp,sp,-64
    80003160:	fc06                	sd	ra,56(sp)
    80003162:	f822                	sd	s0,48(sp)
    80003164:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003166:	0001b717          	auipc	a4,0x1b
    8000316a:	37672703          	lw	a4,886(a4) # 8001e4dc <sb+0xc>
    8000316e:	4785                	li	a5,1
    80003170:	06e7f063          	bgeu	a5,a4,800031d0 <ialloc+0x72>
    80003174:	f426                	sd	s1,40(sp)
    80003176:	f04a                	sd	s2,32(sp)
    80003178:	ec4e                	sd	s3,24(sp)
    8000317a:	e852                	sd	s4,16(sp)
    8000317c:	e456                	sd	s5,8(sp)
    8000317e:	e05a                	sd	s6,0(sp)
    80003180:	8aaa                	mv	s5,a0
    80003182:	8b2e                	mv	s6,a1
    80003184:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003186:	0001ba17          	auipc	s4,0x1b
    8000318a:	34aa0a13          	addi	s4,s4,842 # 8001e4d0 <sb>
    8000318e:	00495593          	srli	a1,s2,0x4
    80003192:	018a2783          	lw	a5,24(s4)
    80003196:	9dbd                	addw	a1,a1,a5
    80003198:	8556                	mv	a0,s5
    8000319a:	a69ff0ef          	jal	80002c02 <bread>
    8000319e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800031a0:	05850993          	addi	s3,a0,88
    800031a4:	00f97793          	andi	a5,s2,15
    800031a8:	079a                	slli	a5,a5,0x6
    800031aa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800031ac:	00099783          	lh	a5,0(s3)
    800031b0:	cb9d                	beqz	a5,800031e6 <ialloc+0x88>
    brelse(bp);
    800031b2:	b59ff0ef          	jal	80002d0a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800031b6:	0905                	addi	s2,s2,1
    800031b8:	00ca2703          	lw	a4,12(s4)
    800031bc:	0009079b          	sext.w	a5,s2
    800031c0:	fce7e7e3          	bltu	a5,a4,8000318e <ialloc+0x30>
    800031c4:	74a2                	ld	s1,40(sp)
    800031c6:	7902                	ld	s2,32(sp)
    800031c8:	69e2                	ld	s3,24(sp)
    800031ca:	6a42                	ld	s4,16(sp)
    800031cc:	6aa2                	ld	s5,8(sp)
    800031ce:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    800031d0:	00004517          	auipc	a0,0x4
    800031d4:	2a850513          	addi	a0,a0,680 # 80007478 <etext+0x478>
    800031d8:	b22fd0ef          	jal	800004fa <printf>
  return 0;
    800031dc:	4501                	li	a0,0
}
    800031de:	70e2                	ld	ra,56(sp)
    800031e0:	7442                	ld	s0,48(sp)
    800031e2:	6121                	addi	sp,sp,64
    800031e4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800031e6:	04000613          	li	a2,64
    800031ea:	4581                	li	a1,0
    800031ec:	854e                	mv	a0,s3
    800031ee:	ab5fd0ef          	jal	80000ca2 <memset>
      dip->type = type;
    800031f2:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800031f6:	8526                	mv	a0,s1
    800031f8:	445000ef          	jal	80003e3c <log_write>
      brelse(bp);
    800031fc:	8526                	mv	a0,s1
    800031fe:	b0dff0ef          	jal	80002d0a <brelse>
      return iget(dev, inum);
    80003202:	0009059b          	sext.w	a1,s2
    80003206:	8556                	mv	a0,s5
    80003208:	e53ff0ef          	jal	8000305a <iget>
    8000320c:	74a2                	ld	s1,40(sp)
    8000320e:	7902                	ld	s2,32(sp)
    80003210:	69e2                	ld	s3,24(sp)
    80003212:	6a42                	ld	s4,16(sp)
    80003214:	6aa2                	ld	s5,8(sp)
    80003216:	6b02                	ld	s6,0(sp)
    80003218:	b7d9                	j	800031de <ialloc+0x80>

000000008000321a <iupdate>:
{
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	e426                	sd	s1,8(sp)
    80003222:	e04a                	sd	s2,0(sp)
    80003224:	1000                	addi	s0,sp,32
    80003226:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003228:	415c                	lw	a5,4(a0)
    8000322a:	0047d79b          	srliw	a5,a5,0x4
    8000322e:	0001b597          	auipc	a1,0x1b
    80003232:	2ba5a583          	lw	a1,698(a1) # 8001e4e8 <sb+0x18>
    80003236:	9dbd                	addw	a1,a1,a5
    80003238:	4108                	lw	a0,0(a0)
    8000323a:	9c9ff0ef          	jal	80002c02 <bread>
    8000323e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003240:	05850793          	addi	a5,a0,88
    80003244:	40d8                	lw	a4,4(s1)
    80003246:	8b3d                	andi	a4,a4,15
    80003248:	071a                	slli	a4,a4,0x6
    8000324a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000324c:	04449703          	lh	a4,68(s1)
    80003250:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003254:	04649703          	lh	a4,70(s1)
    80003258:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000325c:	04849703          	lh	a4,72(s1)
    80003260:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003264:	04a49703          	lh	a4,74(s1)
    80003268:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000326c:	44f8                	lw	a4,76(s1)
    8000326e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003270:	03400613          	li	a2,52
    80003274:	05048593          	addi	a1,s1,80
    80003278:	00c78513          	addi	a0,a5,12
    8000327c:	a83fd0ef          	jal	80000cfe <memmove>
  log_write(bp);
    80003280:	854a                	mv	a0,s2
    80003282:	3bb000ef          	jal	80003e3c <log_write>
  brelse(bp);
    80003286:	854a                	mv	a0,s2
    80003288:	a83ff0ef          	jal	80002d0a <brelse>
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6902                	ld	s2,0(sp)
    80003294:	6105                	addi	sp,sp,32
    80003296:	8082                	ret

0000000080003298 <idup>:
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	e426                	sd	s1,8(sp)
    800032a0:	1000                	addi	s0,sp,32
    800032a2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800032a4:	0001b517          	auipc	a0,0x1b
    800032a8:	24c50513          	addi	a0,a0,588 # 8001e4f0 <itable>
    800032ac:	923fd0ef          	jal	80000bce <acquire>
  ip->ref++;
    800032b0:	449c                	lw	a5,8(s1)
    800032b2:	2785                	addiw	a5,a5,1
    800032b4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800032b6:	0001b517          	auipc	a0,0x1b
    800032ba:	23a50513          	addi	a0,a0,570 # 8001e4f0 <itable>
    800032be:	9a9fd0ef          	jal	80000c66 <release>
}
    800032c2:	8526                	mv	a0,s1
    800032c4:	60e2                	ld	ra,24(sp)
    800032c6:	6442                	ld	s0,16(sp)
    800032c8:	64a2                	ld	s1,8(sp)
    800032ca:	6105                	addi	sp,sp,32
    800032cc:	8082                	ret

00000000800032ce <ilock>:
{
    800032ce:	1101                	addi	sp,sp,-32
    800032d0:	ec06                	sd	ra,24(sp)
    800032d2:	e822                	sd	s0,16(sp)
    800032d4:	e426                	sd	s1,8(sp)
    800032d6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800032d8:	cd19                	beqz	a0,800032f6 <ilock+0x28>
    800032da:	84aa                	mv	s1,a0
    800032dc:	451c                	lw	a5,8(a0)
    800032de:	00f05c63          	blez	a5,800032f6 <ilock+0x28>
  acquiresleep(&ip->lock);
    800032e2:	0541                	addi	a0,a0,16
    800032e4:	451000ef          	jal	80003f34 <acquiresleep>
  if(ip->valid == 0){
    800032e8:	40bc                	lw	a5,64(s1)
    800032ea:	cf89                	beqz	a5,80003304 <ilock+0x36>
}
    800032ec:	60e2                	ld	ra,24(sp)
    800032ee:	6442                	ld	s0,16(sp)
    800032f0:	64a2                	ld	s1,8(sp)
    800032f2:	6105                	addi	sp,sp,32
    800032f4:	8082                	ret
    800032f6:	e04a                	sd	s2,0(sp)
    panic("ilock");
    800032f8:	00004517          	auipc	a0,0x4
    800032fc:	19850513          	addi	a0,a0,408 # 80007490 <etext+0x490>
    80003300:	ce0fd0ef          	jal	800007e0 <panic>
    80003304:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003306:	40dc                	lw	a5,4(s1)
    80003308:	0047d79b          	srliw	a5,a5,0x4
    8000330c:	0001b597          	auipc	a1,0x1b
    80003310:	1dc5a583          	lw	a1,476(a1) # 8001e4e8 <sb+0x18>
    80003314:	9dbd                	addw	a1,a1,a5
    80003316:	4088                	lw	a0,0(s1)
    80003318:	8ebff0ef          	jal	80002c02 <bread>
    8000331c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000331e:	05850593          	addi	a1,a0,88
    80003322:	40dc                	lw	a5,4(s1)
    80003324:	8bbd                	andi	a5,a5,15
    80003326:	079a                	slli	a5,a5,0x6
    80003328:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000332a:	00059783          	lh	a5,0(a1)
    8000332e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003332:	00259783          	lh	a5,2(a1)
    80003336:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000333a:	00459783          	lh	a5,4(a1)
    8000333e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003342:	00659783          	lh	a5,6(a1)
    80003346:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000334a:	459c                	lw	a5,8(a1)
    8000334c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000334e:	03400613          	li	a2,52
    80003352:	05b1                	addi	a1,a1,12
    80003354:	05048513          	addi	a0,s1,80
    80003358:	9a7fd0ef          	jal	80000cfe <memmove>
    brelse(bp);
    8000335c:	854a                	mv	a0,s2
    8000335e:	9adff0ef          	jal	80002d0a <brelse>
    ip->valid = 1;
    80003362:	4785                	li	a5,1
    80003364:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003366:	04449783          	lh	a5,68(s1)
    8000336a:	c399                	beqz	a5,80003370 <ilock+0xa2>
    8000336c:	6902                	ld	s2,0(sp)
    8000336e:	bfbd                	j	800032ec <ilock+0x1e>
      panic("ilock: no type");
    80003370:	00004517          	auipc	a0,0x4
    80003374:	12850513          	addi	a0,a0,296 # 80007498 <etext+0x498>
    80003378:	c68fd0ef          	jal	800007e0 <panic>

000000008000337c <iunlock>:
{
    8000337c:	1101                	addi	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	e426                	sd	s1,8(sp)
    80003384:	e04a                	sd	s2,0(sp)
    80003386:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003388:	c505                	beqz	a0,800033b0 <iunlock+0x34>
    8000338a:	84aa                	mv	s1,a0
    8000338c:	01050913          	addi	s2,a0,16
    80003390:	854a                	mv	a0,s2
    80003392:	421000ef          	jal	80003fb2 <holdingsleep>
    80003396:	cd09                	beqz	a0,800033b0 <iunlock+0x34>
    80003398:	449c                	lw	a5,8(s1)
    8000339a:	00f05b63          	blez	a5,800033b0 <iunlock+0x34>
  releasesleep(&ip->lock);
    8000339e:	854a                	mv	a0,s2
    800033a0:	3db000ef          	jal	80003f7a <releasesleep>
}
    800033a4:	60e2                	ld	ra,24(sp)
    800033a6:	6442                	ld	s0,16(sp)
    800033a8:	64a2                	ld	s1,8(sp)
    800033aa:	6902                	ld	s2,0(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret
    panic("iunlock");
    800033b0:	00004517          	auipc	a0,0x4
    800033b4:	0f850513          	addi	a0,a0,248 # 800074a8 <etext+0x4a8>
    800033b8:	c28fd0ef          	jal	800007e0 <panic>

00000000800033bc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800033bc:	7179                	addi	sp,sp,-48
    800033be:	f406                	sd	ra,40(sp)
    800033c0:	f022                	sd	s0,32(sp)
    800033c2:	ec26                	sd	s1,24(sp)
    800033c4:	e84a                	sd	s2,16(sp)
    800033c6:	e44e                	sd	s3,8(sp)
    800033c8:	1800                	addi	s0,sp,48
    800033ca:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800033cc:	05050493          	addi	s1,a0,80
    800033d0:	08050913          	addi	s2,a0,128
    800033d4:	a021                	j	800033dc <itrunc+0x20>
    800033d6:	0491                	addi	s1,s1,4
    800033d8:	01248b63          	beq	s1,s2,800033ee <itrunc+0x32>
    if(ip->addrs[i]){
    800033dc:	408c                	lw	a1,0(s1)
    800033de:	dde5                	beqz	a1,800033d6 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    800033e0:	0009a503          	lw	a0,0(s3)
    800033e4:	a17ff0ef          	jal	80002dfa <bfree>
      ip->addrs[i] = 0;
    800033e8:	0004a023          	sw	zero,0(s1)
    800033ec:	b7ed                	j	800033d6 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    800033ee:	0809a583          	lw	a1,128(s3)
    800033f2:	ed89                	bnez	a1,8000340c <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800033f4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800033f8:	854e                	mv	a0,s3
    800033fa:	e21ff0ef          	jal	8000321a <iupdate>
}
    800033fe:	70a2                	ld	ra,40(sp)
    80003400:	7402                	ld	s0,32(sp)
    80003402:	64e2                	ld	s1,24(sp)
    80003404:	6942                	ld	s2,16(sp)
    80003406:	69a2                	ld	s3,8(sp)
    80003408:	6145                	addi	sp,sp,48
    8000340a:	8082                	ret
    8000340c:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000340e:	0009a503          	lw	a0,0(s3)
    80003412:	ff0ff0ef          	jal	80002c02 <bread>
    80003416:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003418:	05850493          	addi	s1,a0,88
    8000341c:	45850913          	addi	s2,a0,1112
    80003420:	a021                	j	80003428 <itrunc+0x6c>
    80003422:	0491                	addi	s1,s1,4
    80003424:	01248963          	beq	s1,s2,80003436 <itrunc+0x7a>
      if(a[j])
    80003428:	408c                	lw	a1,0(s1)
    8000342a:	dde5                	beqz	a1,80003422 <itrunc+0x66>
        bfree(ip->dev, a[j]);
    8000342c:	0009a503          	lw	a0,0(s3)
    80003430:	9cbff0ef          	jal	80002dfa <bfree>
    80003434:	b7fd                	j	80003422 <itrunc+0x66>
    brelse(bp);
    80003436:	8552                	mv	a0,s4
    80003438:	8d3ff0ef          	jal	80002d0a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000343c:	0809a583          	lw	a1,128(s3)
    80003440:	0009a503          	lw	a0,0(s3)
    80003444:	9b7ff0ef          	jal	80002dfa <bfree>
    ip->addrs[NDIRECT] = 0;
    80003448:	0809a023          	sw	zero,128(s3)
    8000344c:	6a02                	ld	s4,0(sp)
    8000344e:	b75d                	j	800033f4 <itrunc+0x38>

0000000080003450 <iput>:
{
    80003450:	1101                	addi	sp,sp,-32
    80003452:	ec06                	sd	ra,24(sp)
    80003454:	e822                	sd	s0,16(sp)
    80003456:	e426                	sd	s1,8(sp)
    80003458:	1000                	addi	s0,sp,32
    8000345a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000345c:	0001b517          	auipc	a0,0x1b
    80003460:	09450513          	addi	a0,a0,148 # 8001e4f0 <itable>
    80003464:	f6afd0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003468:	4498                	lw	a4,8(s1)
    8000346a:	4785                	li	a5,1
    8000346c:	02f70063          	beq	a4,a5,8000348c <iput+0x3c>
  ip->ref--;
    80003470:	449c                	lw	a5,8(s1)
    80003472:	37fd                	addiw	a5,a5,-1
    80003474:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003476:	0001b517          	auipc	a0,0x1b
    8000347a:	07a50513          	addi	a0,a0,122 # 8001e4f0 <itable>
    8000347e:	fe8fd0ef          	jal	80000c66 <release>
}
    80003482:	60e2                	ld	ra,24(sp)
    80003484:	6442                	ld	s0,16(sp)
    80003486:	64a2                	ld	s1,8(sp)
    80003488:	6105                	addi	sp,sp,32
    8000348a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000348c:	40bc                	lw	a5,64(s1)
    8000348e:	d3ed                	beqz	a5,80003470 <iput+0x20>
    80003490:	04a49783          	lh	a5,74(s1)
    80003494:	fff1                	bnez	a5,80003470 <iput+0x20>
    80003496:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003498:	01048913          	addi	s2,s1,16
    8000349c:	854a                	mv	a0,s2
    8000349e:	297000ef          	jal	80003f34 <acquiresleep>
    release(&itable.lock);
    800034a2:	0001b517          	auipc	a0,0x1b
    800034a6:	04e50513          	addi	a0,a0,78 # 8001e4f0 <itable>
    800034aa:	fbcfd0ef          	jal	80000c66 <release>
    itrunc(ip);
    800034ae:	8526                	mv	a0,s1
    800034b0:	f0dff0ef          	jal	800033bc <itrunc>
    ip->type = 0;
    800034b4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800034b8:	8526                	mv	a0,s1
    800034ba:	d61ff0ef          	jal	8000321a <iupdate>
    ip->valid = 0;
    800034be:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800034c2:	854a                	mv	a0,s2
    800034c4:	2b7000ef          	jal	80003f7a <releasesleep>
    acquire(&itable.lock);
    800034c8:	0001b517          	auipc	a0,0x1b
    800034cc:	02850513          	addi	a0,a0,40 # 8001e4f0 <itable>
    800034d0:	efefd0ef          	jal	80000bce <acquire>
    800034d4:	6902                	ld	s2,0(sp)
    800034d6:	bf69                	j	80003470 <iput+0x20>

00000000800034d8 <iunlockput>:
{
    800034d8:	1101                	addi	sp,sp,-32
    800034da:	ec06                	sd	ra,24(sp)
    800034dc:	e822                	sd	s0,16(sp)
    800034de:	e426                	sd	s1,8(sp)
    800034e0:	1000                	addi	s0,sp,32
    800034e2:	84aa                	mv	s1,a0
  iunlock(ip);
    800034e4:	e99ff0ef          	jal	8000337c <iunlock>
  iput(ip);
    800034e8:	8526                	mv	a0,s1
    800034ea:	f67ff0ef          	jal	80003450 <iput>
}
    800034ee:	60e2                	ld	ra,24(sp)
    800034f0:	6442                	ld	s0,16(sp)
    800034f2:	64a2                	ld	s1,8(sp)
    800034f4:	6105                	addi	sp,sp,32
    800034f6:	8082                	ret

00000000800034f8 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800034f8:	0001b717          	auipc	a4,0x1b
    800034fc:	fe472703          	lw	a4,-28(a4) # 8001e4dc <sb+0xc>
    80003500:	4785                	li	a5,1
    80003502:	0ae7ff63          	bgeu	a5,a4,800035c0 <ireclaim+0xc8>
{
    80003506:	7139                	addi	sp,sp,-64
    80003508:	fc06                	sd	ra,56(sp)
    8000350a:	f822                	sd	s0,48(sp)
    8000350c:	f426                	sd	s1,40(sp)
    8000350e:	f04a                	sd	s2,32(sp)
    80003510:	ec4e                	sd	s3,24(sp)
    80003512:	e852                	sd	s4,16(sp)
    80003514:	e456                	sd	s5,8(sp)
    80003516:	e05a                	sd	s6,0(sp)
    80003518:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000351a:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000351c:	00050a1b          	sext.w	s4,a0
    80003520:	0001ba97          	auipc	s5,0x1b
    80003524:	fb0a8a93          	addi	s5,s5,-80 # 8001e4d0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003528:	00004b17          	auipc	s6,0x4
    8000352c:	f88b0b13          	addi	s6,s6,-120 # 800074b0 <etext+0x4b0>
    80003530:	a099                	j	80003576 <ireclaim+0x7e>
    80003532:	85ce                	mv	a1,s3
    80003534:	855a                	mv	a0,s6
    80003536:	fc5fc0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    8000353a:	85ce                	mv	a1,s3
    8000353c:	8552                	mv	a0,s4
    8000353e:	b1dff0ef          	jal	8000305a <iget>
    80003542:	89aa                	mv	s3,a0
    brelse(bp);
    80003544:	854a                	mv	a0,s2
    80003546:	fc4ff0ef          	jal	80002d0a <brelse>
    if (ip) {
    8000354a:	00098f63          	beqz	s3,80003568 <ireclaim+0x70>
      begin_op();
    8000354e:	76a000ef          	jal	80003cb8 <begin_op>
      ilock(ip);
    80003552:	854e                	mv	a0,s3
    80003554:	d7bff0ef          	jal	800032ce <ilock>
      iunlock(ip);
    80003558:	854e                	mv	a0,s3
    8000355a:	e23ff0ef          	jal	8000337c <iunlock>
      iput(ip);
    8000355e:	854e                	mv	a0,s3
    80003560:	ef1ff0ef          	jal	80003450 <iput>
      end_op();
    80003564:	7be000ef          	jal	80003d22 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003568:	0485                	addi	s1,s1,1
    8000356a:	00caa703          	lw	a4,12(s5)
    8000356e:	0004879b          	sext.w	a5,s1
    80003572:	02e7fd63          	bgeu	a5,a4,800035ac <ireclaim+0xb4>
    80003576:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000357a:	0044d593          	srli	a1,s1,0x4
    8000357e:	018aa783          	lw	a5,24(s5)
    80003582:	9dbd                	addw	a1,a1,a5
    80003584:	8552                	mv	a0,s4
    80003586:	e7cff0ef          	jal	80002c02 <bread>
    8000358a:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    8000358c:	05850793          	addi	a5,a0,88
    80003590:	00f9f713          	andi	a4,s3,15
    80003594:	071a                	slli	a4,a4,0x6
    80003596:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003598:	00079703          	lh	a4,0(a5)
    8000359c:	c701                	beqz	a4,800035a4 <ireclaim+0xac>
    8000359e:	00679783          	lh	a5,6(a5)
    800035a2:	dbc1                	beqz	a5,80003532 <ireclaim+0x3a>
    brelse(bp);
    800035a4:	854a                	mv	a0,s2
    800035a6:	f64ff0ef          	jal	80002d0a <brelse>
    if (ip) {
    800035aa:	bf7d                	j	80003568 <ireclaim+0x70>
}
    800035ac:	70e2                	ld	ra,56(sp)
    800035ae:	7442                	ld	s0,48(sp)
    800035b0:	74a2                	ld	s1,40(sp)
    800035b2:	7902                	ld	s2,32(sp)
    800035b4:	69e2                	ld	s3,24(sp)
    800035b6:	6a42                	ld	s4,16(sp)
    800035b8:	6aa2                	ld	s5,8(sp)
    800035ba:	6b02                	ld	s6,0(sp)
    800035bc:	6121                	addi	sp,sp,64
    800035be:	8082                	ret
    800035c0:	8082                	ret

00000000800035c2 <fsinit>:
fsinit(int dev) {
    800035c2:	7179                	addi	sp,sp,-48
    800035c4:	f406                	sd	ra,40(sp)
    800035c6:	f022                	sd	s0,32(sp)
    800035c8:	ec26                	sd	s1,24(sp)
    800035ca:	e84a                	sd	s2,16(sp)
    800035cc:	e44e                	sd	s3,8(sp)
    800035ce:	1800                	addi	s0,sp,48
    800035d0:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800035d2:	4585                	li	a1,1
    800035d4:	e2eff0ef          	jal	80002c02 <bread>
    800035d8:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035da:	0001b997          	auipc	s3,0x1b
    800035de:	ef698993          	addi	s3,s3,-266 # 8001e4d0 <sb>
    800035e2:	02000613          	li	a2,32
    800035e6:	05850593          	addi	a1,a0,88
    800035ea:	854e                	mv	a0,s3
    800035ec:	f12fd0ef          	jal	80000cfe <memmove>
  brelse(bp);
    800035f0:	854a                	mv	a0,s2
    800035f2:	f18ff0ef          	jal	80002d0a <brelse>
  if(sb.magic != FSMAGIC)
    800035f6:	0009a703          	lw	a4,0(s3)
    800035fa:	102037b7          	lui	a5,0x10203
    800035fe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003602:	02f71363          	bne	a4,a5,80003628 <fsinit+0x66>
  initlog(dev, &sb);
    80003606:	0001b597          	auipc	a1,0x1b
    8000360a:	eca58593          	addi	a1,a1,-310 # 8001e4d0 <sb>
    8000360e:	8526                	mv	a0,s1
    80003610:	62a000ef          	jal	80003c3a <initlog>
  ireclaim(dev);
    80003614:	8526                	mv	a0,s1
    80003616:	ee3ff0ef          	jal	800034f8 <ireclaim>
}
    8000361a:	70a2                	ld	ra,40(sp)
    8000361c:	7402                	ld	s0,32(sp)
    8000361e:	64e2                	ld	s1,24(sp)
    80003620:	6942                	ld	s2,16(sp)
    80003622:	69a2                	ld	s3,8(sp)
    80003624:	6145                	addi	sp,sp,48
    80003626:	8082                	ret
    panic("invalid file system");
    80003628:	00004517          	auipc	a0,0x4
    8000362c:	ea850513          	addi	a0,a0,-344 # 800074d0 <etext+0x4d0>
    80003630:	9b0fd0ef          	jal	800007e0 <panic>

0000000080003634 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003634:	1141                	addi	sp,sp,-16
    80003636:	e422                	sd	s0,8(sp)
    80003638:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000363a:	411c                	lw	a5,0(a0)
    8000363c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000363e:	415c                	lw	a5,4(a0)
    80003640:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003642:	04451783          	lh	a5,68(a0)
    80003646:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000364a:	04a51783          	lh	a5,74(a0)
    8000364e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003652:	04c56783          	lwu	a5,76(a0)
    80003656:	e99c                	sd	a5,16(a1)
}
    80003658:	6422                	ld	s0,8(sp)
    8000365a:	0141                	addi	sp,sp,16
    8000365c:	8082                	ret

000000008000365e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000365e:	457c                	lw	a5,76(a0)
    80003660:	0ed7eb63          	bltu	a5,a3,80003756 <readi+0xf8>
{
    80003664:	7159                	addi	sp,sp,-112
    80003666:	f486                	sd	ra,104(sp)
    80003668:	f0a2                	sd	s0,96(sp)
    8000366a:	eca6                	sd	s1,88(sp)
    8000366c:	e0d2                	sd	s4,64(sp)
    8000366e:	fc56                	sd	s5,56(sp)
    80003670:	f85a                	sd	s6,48(sp)
    80003672:	f45e                	sd	s7,40(sp)
    80003674:	1880                	addi	s0,sp,112
    80003676:	8b2a                	mv	s6,a0
    80003678:	8bae                	mv	s7,a1
    8000367a:	8a32                	mv	s4,a2
    8000367c:	84b6                	mv	s1,a3
    8000367e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003680:	9f35                	addw	a4,a4,a3
    return 0;
    80003682:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003684:	0cd76063          	bltu	a4,a3,80003744 <readi+0xe6>
    80003688:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    8000368a:	00e7f463          	bgeu	a5,a4,80003692 <readi+0x34>
    n = ip->size - off;
    8000368e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003692:	080a8f63          	beqz	s5,80003730 <readi+0xd2>
    80003696:	e8ca                	sd	s2,80(sp)
    80003698:	f062                	sd	s8,32(sp)
    8000369a:	ec66                	sd	s9,24(sp)
    8000369c:	e86a                	sd	s10,16(sp)
    8000369e:	e46e                	sd	s11,8(sp)
    800036a0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800036a2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800036a6:	5c7d                	li	s8,-1
    800036a8:	a80d                	j	800036da <readi+0x7c>
    800036aa:	020d1d93          	slli	s11,s10,0x20
    800036ae:	020ddd93          	srli	s11,s11,0x20
    800036b2:	05890613          	addi	a2,s2,88
    800036b6:	86ee                	mv	a3,s11
    800036b8:	963a                	add	a2,a2,a4
    800036ba:	85d2                	mv	a1,s4
    800036bc:	855e                	mv	a0,s7
    800036be:	c2dfe0ef          	jal	800022ea <either_copyout>
    800036c2:	05850763          	beq	a0,s8,80003710 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	e42ff0ef          	jal	80002d0a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800036cc:	013d09bb          	addw	s3,s10,s3
    800036d0:	009d04bb          	addw	s1,s10,s1
    800036d4:	9a6e                	add	s4,s4,s11
    800036d6:	0559f763          	bgeu	s3,s5,80003724 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    800036da:	00a4d59b          	srliw	a1,s1,0xa
    800036de:	855a                	mv	a0,s6
    800036e0:	8a7ff0ef          	jal	80002f86 <bmap>
    800036e4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800036e8:	c5b1                	beqz	a1,80003734 <readi+0xd6>
    bp = bread(ip->dev, addr);
    800036ea:	000b2503          	lw	a0,0(s6)
    800036ee:	d14ff0ef          	jal	80002c02 <bread>
    800036f2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800036f4:	3ff4f713          	andi	a4,s1,1023
    800036f8:	40ec87bb          	subw	a5,s9,a4
    800036fc:	413a86bb          	subw	a3,s5,s3
    80003700:	8d3e                	mv	s10,a5
    80003702:	2781                	sext.w	a5,a5
    80003704:	0006861b          	sext.w	a2,a3
    80003708:	faf671e3          	bgeu	a2,a5,800036aa <readi+0x4c>
    8000370c:	8d36                	mv	s10,a3
    8000370e:	bf71                	j	800036aa <readi+0x4c>
      brelse(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	df8ff0ef          	jal	80002d0a <brelse>
      tot = -1;
    80003716:	59fd                	li	s3,-1
      break;
    80003718:	6946                	ld	s2,80(sp)
    8000371a:	7c02                	ld	s8,32(sp)
    8000371c:	6ce2                	ld	s9,24(sp)
    8000371e:	6d42                	ld	s10,16(sp)
    80003720:	6da2                	ld	s11,8(sp)
    80003722:	a831                	j	8000373e <readi+0xe0>
    80003724:	6946                	ld	s2,80(sp)
    80003726:	7c02                	ld	s8,32(sp)
    80003728:	6ce2                	ld	s9,24(sp)
    8000372a:	6d42                	ld	s10,16(sp)
    8000372c:	6da2                	ld	s11,8(sp)
    8000372e:	a801                	j	8000373e <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003730:	89d6                	mv	s3,s5
    80003732:	a031                	j	8000373e <readi+0xe0>
    80003734:	6946                	ld	s2,80(sp)
    80003736:	7c02                	ld	s8,32(sp)
    80003738:	6ce2                	ld	s9,24(sp)
    8000373a:	6d42                	ld	s10,16(sp)
    8000373c:	6da2                	ld	s11,8(sp)
  }
  return tot;
    8000373e:	0009851b          	sext.w	a0,s3
    80003742:	69a6                	ld	s3,72(sp)
}
    80003744:	70a6                	ld	ra,104(sp)
    80003746:	7406                	ld	s0,96(sp)
    80003748:	64e6                	ld	s1,88(sp)
    8000374a:	6a06                	ld	s4,64(sp)
    8000374c:	7ae2                	ld	s5,56(sp)
    8000374e:	7b42                	ld	s6,48(sp)
    80003750:	7ba2                	ld	s7,40(sp)
    80003752:	6165                	addi	sp,sp,112
    80003754:	8082                	ret
    return 0;
    80003756:	4501                	li	a0,0
}
    80003758:	8082                	ret

000000008000375a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000375a:	457c                	lw	a5,76(a0)
    8000375c:	10d7e063          	bltu	a5,a3,8000385c <writei+0x102>
{
    80003760:	7159                	addi	sp,sp,-112
    80003762:	f486                	sd	ra,104(sp)
    80003764:	f0a2                	sd	s0,96(sp)
    80003766:	e8ca                	sd	s2,80(sp)
    80003768:	e0d2                	sd	s4,64(sp)
    8000376a:	fc56                	sd	s5,56(sp)
    8000376c:	f85a                	sd	s6,48(sp)
    8000376e:	f45e                	sd	s7,40(sp)
    80003770:	1880                	addi	s0,sp,112
    80003772:	8aaa                	mv	s5,a0
    80003774:	8bae                	mv	s7,a1
    80003776:	8a32                	mv	s4,a2
    80003778:	8936                	mv	s2,a3
    8000377a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000377c:	00e687bb          	addw	a5,a3,a4
    80003780:	0ed7e063          	bltu	a5,a3,80003860 <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003784:	00043737          	lui	a4,0x43
    80003788:	0cf76e63          	bltu	a4,a5,80003864 <writei+0x10a>
    8000378c:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000378e:	0a0b0f63          	beqz	s6,8000384c <writei+0xf2>
    80003792:	eca6                	sd	s1,88(sp)
    80003794:	f062                	sd	s8,32(sp)
    80003796:	ec66                	sd	s9,24(sp)
    80003798:	e86a                	sd	s10,16(sp)
    8000379a:	e46e                	sd	s11,8(sp)
    8000379c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000379e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800037a2:	5c7d                	li	s8,-1
    800037a4:	a825                	j	800037dc <writei+0x82>
    800037a6:	020d1d93          	slli	s11,s10,0x20
    800037aa:	020ddd93          	srli	s11,s11,0x20
    800037ae:	05848513          	addi	a0,s1,88
    800037b2:	86ee                	mv	a3,s11
    800037b4:	8652                	mv	a2,s4
    800037b6:	85de                	mv	a1,s7
    800037b8:	953a                	add	a0,a0,a4
    800037ba:	b7bfe0ef          	jal	80002334 <either_copyin>
    800037be:	05850a63          	beq	a0,s8,80003812 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    800037c2:	8526                	mv	a0,s1
    800037c4:	678000ef          	jal	80003e3c <log_write>
    brelse(bp);
    800037c8:	8526                	mv	a0,s1
    800037ca:	d40ff0ef          	jal	80002d0a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800037ce:	013d09bb          	addw	s3,s10,s3
    800037d2:	012d093b          	addw	s2,s10,s2
    800037d6:	9a6e                	add	s4,s4,s11
    800037d8:	0569f063          	bgeu	s3,s6,80003818 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    800037dc:	00a9559b          	srliw	a1,s2,0xa
    800037e0:	8556                	mv	a0,s5
    800037e2:	fa4ff0ef          	jal	80002f86 <bmap>
    800037e6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800037ea:	c59d                	beqz	a1,80003818 <writei+0xbe>
    bp = bread(ip->dev, addr);
    800037ec:	000aa503          	lw	a0,0(s5)
    800037f0:	c12ff0ef          	jal	80002c02 <bread>
    800037f4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800037f6:	3ff97713          	andi	a4,s2,1023
    800037fa:	40ec87bb          	subw	a5,s9,a4
    800037fe:	413b06bb          	subw	a3,s6,s3
    80003802:	8d3e                	mv	s10,a5
    80003804:	2781                	sext.w	a5,a5
    80003806:	0006861b          	sext.w	a2,a3
    8000380a:	f8f67ee3          	bgeu	a2,a5,800037a6 <writei+0x4c>
    8000380e:	8d36                	mv	s10,a3
    80003810:	bf59                	j	800037a6 <writei+0x4c>
      brelse(bp);
    80003812:	8526                	mv	a0,s1
    80003814:	cf6ff0ef          	jal	80002d0a <brelse>
  }

  if(off > ip->size)
    80003818:	04caa783          	lw	a5,76(s5)
    8000381c:	0327fa63          	bgeu	a5,s2,80003850 <writei+0xf6>
    ip->size = off;
    80003820:	052aa623          	sw	s2,76(s5)
    80003824:	64e6                	ld	s1,88(sp)
    80003826:	7c02                	ld	s8,32(sp)
    80003828:	6ce2                	ld	s9,24(sp)
    8000382a:	6d42                	ld	s10,16(sp)
    8000382c:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000382e:	8556                	mv	a0,s5
    80003830:	9ebff0ef          	jal	8000321a <iupdate>

  return tot;
    80003834:	0009851b          	sext.w	a0,s3
    80003838:	69a6                	ld	s3,72(sp)
}
    8000383a:	70a6                	ld	ra,104(sp)
    8000383c:	7406                	ld	s0,96(sp)
    8000383e:	6946                	ld	s2,80(sp)
    80003840:	6a06                	ld	s4,64(sp)
    80003842:	7ae2                	ld	s5,56(sp)
    80003844:	7b42                	ld	s6,48(sp)
    80003846:	7ba2                	ld	s7,40(sp)
    80003848:	6165                	addi	sp,sp,112
    8000384a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000384c:	89da                	mv	s3,s6
    8000384e:	b7c5                	j	8000382e <writei+0xd4>
    80003850:	64e6                	ld	s1,88(sp)
    80003852:	7c02                	ld	s8,32(sp)
    80003854:	6ce2                	ld	s9,24(sp)
    80003856:	6d42                	ld	s10,16(sp)
    80003858:	6da2                	ld	s11,8(sp)
    8000385a:	bfd1                	j	8000382e <writei+0xd4>
    return -1;
    8000385c:	557d                	li	a0,-1
}
    8000385e:	8082                	ret
    return -1;
    80003860:	557d                	li	a0,-1
    80003862:	bfe1                	j	8000383a <writei+0xe0>
    return -1;
    80003864:	557d                	li	a0,-1
    80003866:	bfd1                	j	8000383a <writei+0xe0>

0000000080003868 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003868:	1141                	addi	sp,sp,-16
    8000386a:	e406                	sd	ra,8(sp)
    8000386c:	e022                	sd	s0,0(sp)
    8000386e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003870:	4639                	li	a2,14
    80003872:	cfcfd0ef          	jal	80000d6e <strncmp>
}
    80003876:	60a2                	ld	ra,8(sp)
    80003878:	6402                	ld	s0,0(sp)
    8000387a:	0141                	addi	sp,sp,16
    8000387c:	8082                	ret

000000008000387e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000387e:	7139                	addi	sp,sp,-64
    80003880:	fc06                	sd	ra,56(sp)
    80003882:	f822                	sd	s0,48(sp)
    80003884:	f426                	sd	s1,40(sp)
    80003886:	f04a                	sd	s2,32(sp)
    80003888:	ec4e                	sd	s3,24(sp)
    8000388a:	e852                	sd	s4,16(sp)
    8000388c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000388e:	04451703          	lh	a4,68(a0)
    80003892:	4785                	li	a5,1
    80003894:	00f71a63          	bne	a4,a5,800038a8 <dirlookup+0x2a>
    80003898:	892a                	mv	s2,a0
    8000389a:	89ae                	mv	s3,a1
    8000389c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000389e:	457c                	lw	a5,76(a0)
    800038a0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800038a2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800038a4:	e39d                	bnez	a5,800038ca <dirlookup+0x4c>
    800038a6:	a095                	j	8000390a <dirlookup+0x8c>
    panic("dirlookup not DIR");
    800038a8:	00004517          	auipc	a0,0x4
    800038ac:	c4050513          	addi	a0,a0,-960 # 800074e8 <etext+0x4e8>
    800038b0:	f31fc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    800038b4:	00004517          	auipc	a0,0x4
    800038b8:	c4c50513          	addi	a0,a0,-948 # 80007500 <etext+0x500>
    800038bc:	f25fc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800038c0:	24c1                	addiw	s1,s1,16
    800038c2:	04c92783          	lw	a5,76(s2)
    800038c6:	04f4f163          	bgeu	s1,a5,80003908 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800038ca:	4741                	li	a4,16
    800038cc:	86a6                	mv	a3,s1
    800038ce:	fc040613          	addi	a2,s0,-64
    800038d2:	4581                	li	a1,0
    800038d4:	854a                	mv	a0,s2
    800038d6:	d89ff0ef          	jal	8000365e <readi>
    800038da:	47c1                	li	a5,16
    800038dc:	fcf51ce3          	bne	a0,a5,800038b4 <dirlookup+0x36>
    if(de.inum == 0)
    800038e0:	fc045783          	lhu	a5,-64(s0)
    800038e4:	dff1                	beqz	a5,800038c0 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    800038e6:	fc240593          	addi	a1,s0,-62
    800038ea:	854e                	mv	a0,s3
    800038ec:	f7dff0ef          	jal	80003868 <namecmp>
    800038f0:	f961                	bnez	a0,800038c0 <dirlookup+0x42>
      if(poff)
    800038f2:	000a0463          	beqz	s4,800038fa <dirlookup+0x7c>
        *poff = off;
    800038f6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800038fa:	fc045583          	lhu	a1,-64(s0)
    800038fe:	00092503          	lw	a0,0(s2)
    80003902:	f58ff0ef          	jal	8000305a <iget>
    80003906:	a011                	j	8000390a <dirlookup+0x8c>
  return 0;
    80003908:	4501                	li	a0,0
}
    8000390a:	70e2                	ld	ra,56(sp)
    8000390c:	7442                	ld	s0,48(sp)
    8000390e:	74a2                	ld	s1,40(sp)
    80003910:	7902                	ld	s2,32(sp)
    80003912:	69e2                	ld	s3,24(sp)
    80003914:	6a42                	ld	s4,16(sp)
    80003916:	6121                	addi	sp,sp,64
    80003918:	8082                	ret

000000008000391a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000391a:	711d                	addi	sp,sp,-96
    8000391c:	ec86                	sd	ra,88(sp)
    8000391e:	e8a2                	sd	s0,80(sp)
    80003920:	e4a6                	sd	s1,72(sp)
    80003922:	e0ca                	sd	s2,64(sp)
    80003924:	fc4e                	sd	s3,56(sp)
    80003926:	f852                	sd	s4,48(sp)
    80003928:	f456                	sd	s5,40(sp)
    8000392a:	f05a                	sd	s6,32(sp)
    8000392c:	ec5e                	sd	s7,24(sp)
    8000392e:	e862                	sd	s8,16(sp)
    80003930:	e466                	sd	s9,8(sp)
    80003932:	1080                	addi	s0,sp,96
    80003934:	84aa                	mv	s1,a0
    80003936:	8b2e                	mv	s6,a1
    80003938:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000393a:	00054703          	lbu	a4,0(a0)
    8000393e:	02f00793          	li	a5,47
    80003942:	00f70e63          	beq	a4,a5,8000395e <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003946:	f89fd0ef          	jal	800018ce <myproc>
    8000394a:	16853503          	ld	a0,360(a0)
    8000394e:	94bff0ef          	jal	80003298 <idup>
    80003952:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003954:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003958:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000395a:	4b85                	li	s7,1
    8000395c:	a871                	j	800039f8 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    8000395e:	4585                	li	a1,1
    80003960:	4505                	li	a0,1
    80003962:	ef8ff0ef          	jal	8000305a <iget>
    80003966:	8a2a                	mv	s4,a0
    80003968:	b7f5                	j	80003954 <namex+0x3a>
      iunlockput(ip);
    8000396a:	8552                	mv	a0,s4
    8000396c:	b6dff0ef          	jal	800034d8 <iunlockput>
      return 0;
    80003970:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003972:	8552                	mv	a0,s4
    80003974:	60e6                	ld	ra,88(sp)
    80003976:	6446                	ld	s0,80(sp)
    80003978:	64a6                	ld	s1,72(sp)
    8000397a:	6906                	ld	s2,64(sp)
    8000397c:	79e2                	ld	s3,56(sp)
    8000397e:	7a42                	ld	s4,48(sp)
    80003980:	7aa2                	ld	s5,40(sp)
    80003982:	7b02                	ld	s6,32(sp)
    80003984:	6be2                	ld	s7,24(sp)
    80003986:	6c42                	ld	s8,16(sp)
    80003988:	6ca2                	ld	s9,8(sp)
    8000398a:	6125                	addi	sp,sp,96
    8000398c:	8082                	ret
      iunlock(ip);
    8000398e:	8552                	mv	a0,s4
    80003990:	9edff0ef          	jal	8000337c <iunlock>
      return ip;
    80003994:	bff9                	j	80003972 <namex+0x58>
      iunlockput(ip);
    80003996:	8552                	mv	a0,s4
    80003998:	b41ff0ef          	jal	800034d8 <iunlockput>
      return 0;
    8000399c:	8a4e                	mv	s4,s3
    8000399e:	bfd1                	j	80003972 <namex+0x58>
  len = path - s;
    800039a0:	40998633          	sub	a2,s3,s1
    800039a4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800039a8:	099c5063          	bge	s8,s9,80003a28 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    800039ac:	4639                	li	a2,14
    800039ae:	85a6                	mv	a1,s1
    800039b0:	8556                	mv	a0,s5
    800039b2:	b4cfd0ef          	jal	80000cfe <memmove>
    800039b6:	84ce                	mv	s1,s3
  while(*path == '/')
    800039b8:	0004c783          	lbu	a5,0(s1)
    800039bc:	01279763          	bne	a5,s2,800039ca <namex+0xb0>
    path++;
    800039c0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800039c2:	0004c783          	lbu	a5,0(s1)
    800039c6:	ff278de3          	beq	a5,s2,800039c0 <namex+0xa6>
    ilock(ip);
    800039ca:	8552                	mv	a0,s4
    800039cc:	903ff0ef          	jal	800032ce <ilock>
    if(ip->type != T_DIR){
    800039d0:	044a1783          	lh	a5,68(s4)
    800039d4:	f9779be3          	bne	a5,s7,8000396a <namex+0x50>
    if(nameiparent && *path == '\0'){
    800039d8:	000b0563          	beqz	s6,800039e2 <namex+0xc8>
    800039dc:	0004c783          	lbu	a5,0(s1)
    800039e0:	d7dd                	beqz	a5,8000398e <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    800039e2:	4601                	li	a2,0
    800039e4:	85d6                	mv	a1,s5
    800039e6:	8552                	mv	a0,s4
    800039e8:	e97ff0ef          	jal	8000387e <dirlookup>
    800039ec:	89aa                	mv	s3,a0
    800039ee:	d545                	beqz	a0,80003996 <namex+0x7c>
    iunlockput(ip);
    800039f0:	8552                	mv	a0,s4
    800039f2:	ae7ff0ef          	jal	800034d8 <iunlockput>
    ip = next;
    800039f6:	8a4e                	mv	s4,s3
  while(*path == '/')
    800039f8:	0004c783          	lbu	a5,0(s1)
    800039fc:	01279763          	bne	a5,s2,80003a0a <namex+0xf0>
    path++;
    80003a00:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003a02:	0004c783          	lbu	a5,0(s1)
    80003a06:	ff278de3          	beq	a5,s2,80003a00 <namex+0xe6>
  if(*path == 0)
    80003a0a:	cb8d                	beqz	a5,80003a3c <namex+0x122>
  while(*path != '/' && *path != 0)
    80003a0c:	0004c783          	lbu	a5,0(s1)
    80003a10:	89a6                	mv	s3,s1
  len = path - s;
    80003a12:	4c81                	li	s9,0
    80003a14:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003a16:	01278963          	beq	a5,s2,80003a28 <namex+0x10e>
    80003a1a:	d3d9                	beqz	a5,800039a0 <namex+0x86>
    path++;
    80003a1c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003a1e:	0009c783          	lbu	a5,0(s3)
    80003a22:	ff279ce3          	bne	a5,s2,80003a1a <namex+0x100>
    80003a26:	bfad                	j	800039a0 <namex+0x86>
    memmove(name, s, len);
    80003a28:	2601                	sext.w	a2,a2
    80003a2a:	85a6                	mv	a1,s1
    80003a2c:	8556                	mv	a0,s5
    80003a2e:	ad0fd0ef          	jal	80000cfe <memmove>
    name[len] = 0;
    80003a32:	9cd6                	add	s9,s9,s5
    80003a34:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003a38:	84ce                	mv	s1,s3
    80003a3a:	bfbd                	j	800039b8 <namex+0x9e>
  if(nameiparent){
    80003a3c:	f20b0be3          	beqz	s6,80003972 <namex+0x58>
    iput(ip);
    80003a40:	8552                	mv	a0,s4
    80003a42:	a0fff0ef          	jal	80003450 <iput>
    return 0;
    80003a46:	4a01                	li	s4,0
    80003a48:	b72d                	j	80003972 <namex+0x58>

0000000080003a4a <dirlink>:
{
    80003a4a:	7139                	addi	sp,sp,-64
    80003a4c:	fc06                	sd	ra,56(sp)
    80003a4e:	f822                	sd	s0,48(sp)
    80003a50:	f04a                	sd	s2,32(sp)
    80003a52:	ec4e                	sd	s3,24(sp)
    80003a54:	e852                	sd	s4,16(sp)
    80003a56:	0080                	addi	s0,sp,64
    80003a58:	892a                	mv	s2,a0
    80003a5a:	8a2e                	mv	s4,a1
    80003a5c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003a5e:	4601                	li	a2,0
    80003a60:	e1fff0ef          	jal	8000387e <dirlookup>
    80003a64:	e535                	bnez	a0,80003ad0 <dirlink+0x86>
    80003a66:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a68:	04c92483          	lw	s1,76(s2)
    80003a6c:	c48d                	beqz	s1,80003a96 <dirlink+0x4c>
    80003a6e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a70:	4741                	li	a4,16
    80003a72:	86a6                	mv	a3,s1
    80003a74:	fc040613          	addi	a2,s0,-64
    80003a78:	4581                	li	a1,0
    80003a7a:	854a                	mv	a0,s2
    80003a7c:	be3ff0ef          	jal	8000365e <readi>
    80003a80:	47c1                	li	a5,16
    80003a82:	04f51b63          	bne	a0,a5,80003ad8 <dirlink+0x8e>
    if(de.inum == 0)
    80003a86:	fc045783          	lhu	a5,-64(s0)
    80003a8a:	c791                	beqz	a5,80003a96 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a8c:	24c1                	addiw	s1,s1,16
    80003a8e:	04c92783          	lw	a5,76(s2)
    80003a92:	fcf4efe3          	bltu	s1,a5,80003a70 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003a96:	4639                	li	a2,14
    80003a98:	85d2                	mv	a1,s4
    80003a9a:	fc240513          	addi	a0,s0,-62
    80003a9e:	b06fd0ef          	jal	80000da4 <strncpy>
  de.inum = inum;
    80003aa2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003aa6:	4741                	li	a4,16
    80003aa8:	86a6                	mv	a3,s1
    80003aaa:	fc040613          	addi	a2,s0,-64
    80003aae:	4581                	li	a1,0
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	ca9ff0ef          	jal	8000375a <writei>
    80003ab6:	1541                	addi	a0,a0,-16
    80003ab8:	00a03533          	snez	a0,a0
    80003abc:	40a00533          	neg	a0,a0
    80003ac0:	74a2                	ld	s1,40(sp)
}
    80003ac2:	70e2                	ld	ra,56(sp)
    80003ac4:	7442                	ld	s0,48(sp)
    80003ac6:	7902                	ld	s2,32(sp)
    80003ac8:	69e2                	ld	s3,24(sp)
    80003aca:	6a42                	ld	s4,16(sp)
    80003acc:	6121                	addi	sp,sp,64
    80003ace:	8082                	ret
    iput(ip);
    80003ad0:	981ff0ef          	jal	80003450 <iput>
    return -1;
    80003ad4:	557d                	li	a0,-1
    80003ad6:	b7f5                	j	80003ac2 <dirlink+0x78>
      panic("dirlink read");
    80003ad8:	00004517          	auipc	a0,0x4
    80003adc:	a3850513          	addi	a0,a0,-1480 # 80007510 <etext+0x510>
    80003ae0:	d01fc0ef          	jal	800007e0 <panic>

0000000080003ae4 <namei>:

struct inode*
namei(char *path)
{
    80003ae4:	1101                	addi	sp,sp,-32
    80003ae6:	ec06                	sd	ra,24(sp)
    80003ae8:	e822                	sd	s0,16(sp)
    80003aea:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003aec:	fe040613          	addi	a2,s0,-32
    80003af0:	4581                	li	a1,0
    80003af2:	e29ff0ef          	jal	8000391a <namex>
}
    80003af6:	60e2                	ld	ra,24(sp)
    80003af8:	6442                	ld	s0,16(sp)
    80003afa:	6105                	addi	sp,sp,32
    80003afc:	8082                	ret

0000000080003afe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003afe:	1141                	addi	sp,sp,-16
    80003b00:	e406                	sd	ra,8(sp)
    80003b02:	e022                	sd	s0,0(sp)
    80003b04:	0800                	addi	s0,sp,16
    80003b06:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003b08:	4585                	li	a1,1
    80003b0a:	e11ff0ef          	jal	8000391a <namex>
}
    80003b0e:	60a2                	ld	ra,8(sp)
    80003b10:	6402                	ld	s0,0(sp)
    80003b12:	0141                	addi	sp,sp,16
    80003b14:	8082                	ret

0000000080003b16 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003b16:	1101                	addi	sp,sp,-32
    80003b18:	ec06                	sd	ra,24(sp)
    80003b1a:	e822                	sd	s0,16(sp)
    80003b1c:	e426                	sd	s1,8(sp)
    80003b1e:	e04a                	sd	s2,0(sp)
    80003b20:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003b22:	0001c917          	auipc	s2,0x1c
    80003b26:	47690913          	addi	s2,s2,1142 # 8001ff98 <log>
    80003b2a:	01892583          	lw	a1,24(s2)
    80003b2e:	02492503          	lw	a0,36(s2)
    80003b32:	8d0ff0ef          	jal	80002c02 <bread>
    80003b36:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003b38:	02892603          	lw	a2,40(s2)
    80003b3c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003b3e:	00c05f63          	blez	a2,80003b5c <write_head+0x46>
    80003b42:	0001c717          	auipc	a4,0x1c
    80003b46:	48270713          	addi	a4,a4,1154 # 8001ffc4 <log+0x2c>
    80003b4a:	87aa                	mv	a5,a0
    80003b4c:	060a                	slli	a2,a2,0x2
    80003b4e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003b50:	4314                	lw	a3,0(a4)
    80003b52:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003b54:	0711                	addi	a4,a4,4
    80003b56:	0791                	addi	a5,a5,4
    80003b58:	fec79ce3          	bne	a5,a2,80003b50 <write_head+0x3a>
  }
  bwrite(buf);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	97aff0ef          	jal	80002cd8 <bwrite>
  brelse(buf);
    80003b62:	8526                	mv	a0,s1
    80003b64:	9a6ff0ef          	jal	80002d0a <brelse>
}
    80003b68:	60e2                	ld	ra,24(sp)
    80003b6a:	6442                	ld	s0,16(sp)
    80003b6c:	64a2                	ld	s1,8(sp)
    80003b6e:	6902                	ld	s2,0(sp)
    80003b70:	6105                	addi	sp,sp,32
    80003b72:	8082                	ret

0000000080003b74 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003b74:	0001c797          	auipc	a5,0x1c
    80003b78:	44c7a783          	lw	a5,1100(a5) # 8001ffc0 <log+0x28>
    80003b7c:	0af05e63          	blez	a5,80003c38 <install_trans+0xc4>
{
    80003b80:	715d                	addi	sp,sp,-80
    80003b82:	e486                	sd	ra,72(sp)
    80003b84:	e0a2                	sd	s0,64(sp)
    80003b86:	fc26                	sd	s1,56(sp)
    80003b88:	f84a                	sd	s2,48(sp)
    80003b8a:	f44e                	sd	s3,40(sp)
    80003b8c:	f052                	sd	s4,32(sp)
    80003b8e:	ec56                	sd	s5,24(sp)
    80003b90:	e85a                	sd	s6,16(sp)
    80003b92:	e45e                	sd	s7,8(sp)
    80003b94:	0880                	addi	s0,sp,80
    80003b96:	8b2a                	mv	s6,a0
    80003b98:	0001ca97          	auipc	s5,0x1c
    80003b9c:	42ca8a93          	addi	s5,s5,1068 # 8001ffc4 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ba0:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003ba2:	00004b97          	auipc	s7,0x4
    80003ba6:	97eb8b93          	addi	s7,s7,-1666 # 80007520 <etext+0x520>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003baa:	0001ca17          	auipc	s4,0x1c
    80003bae:	3eea0a13          	addi	s4,s4,1006 # 8001ff98 <log>
    80003bb2:	a025                	j	80003bda <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003bb4:	000aa603          	lw	a2,0(s5)
    80003bb8:	85ce                	mv	a1,s3
    80003bba:	855e                	mv	a0,s7
    80003bbc:	93ffc0ef          	jal	800004fa <printf>
    80003bc0:	a839                	j	80003bde <install_trans+0x6a>
    brelse(lbuf);
    80003bc2:	854a                	mv	a0,s2
    80003bc4:	946ff0ef          	jal	80002d0a <brelse>
    brelse(dbuf);
    80003bc8:	8526                	mv	a0,s1
    80003bca:	940ff0ef          	jal	80002d0a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003bce:	2985                	addiw	s3,s3,1
    80003bd0:	0a91                	addi	s5,s5,4
    80003bd2:	028a2783          	lw	a5,40(s4)
    80003bd6:	04f9d663          	bge	s3,a5,80003c22 <install_trans+0xae>
    if(recovering) {
    80003bda:	fc0b1de3          	bnez	s6,80003bb4 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003bde:	018a2583          	lw	a1,24(s4)
    80003be2:	013585bb          	addw	a1,a1,s3
    80003be6:	2585                	addiw	a1,a1,1
    80003be8:	024a2503          	lw	a0,36(s4)
    80003bec:	816ff0ef          	jal	80002c02 <bread>
    80003bf0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003bf2:	000aa583          	lw	a1,0(s5)
    80003bf6:	024a2503          	lw	a0,36(s4)
    80003bfa:	808ff0ef          	jal	80002c02 <bread>
    80003bfe:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003c00:	40000613          	li	a2,1024
    80003c04:	05890593          	addi	a1,s2,88
    80003c08:	05850513          	addi	a0,a0,88
    80003c0c:	8f2fd0ef          	jal	80000cfe <memmove>
    bwrite(dbuf);  // write dst to disk
    80003c10:	8526                	mv	a0,s1
    80003c12:	8c6ff0ef          	jal	80002cd8 <bwrite>
    if(recovering == 0)
    80003c16:	fa0b16e3          	bnez	s6,80003bc2 <install_trans+0x4e>
      bunpin(dbuf);
    80003c1a:	8526                	mv	a0,s1
    80003c1c:	9aaff0ef          	jal	80002dc6 <bunpin>
    80003c20:	b74d                	j	80003bc2 <install_trans+0x4e>
}
    80003c22:	60a6                	ld	ra,72(sp)
    80003c24:	6406                	ld	s0,64(sp)
    80003c26:	74e2                	ld	s1,56(sp)
    80003c28:	7942                	ld	s2,48(sp)
    80003c2a:	79a2                	ld	s3,40(sp)
    80003c2c:	7a02                	ld	s4,32(sp)
    80003c2e:	6ae2                	ld	s5,24(sp)
    80003c30:	6b42                	ld	s6,16(sp)
    80003c32:	6ba2                	ld	s7,8(sp)
    80003c34:	6161                	addi	sp,sp,80
    80003c36:	8082                	ret
    80003c38:	8082                	ret

0000000080003c3a <initlog>:
{
    80003c3a:	7179                	addi	sp,sp,-48
    80003c3c:	f406                	sd	ra,40(sp)
    80003c3e:	f022                	sd	s0,32(sp)
    80003c40:	ec26                	sd	s1,24(sp)
    80003c42:	e84a                	sd	s2,16(sp)
    80003c44:	e44e                	sd	s3,8(sp)
    80003c46:	1800                	addi	s0,sp,48
    80003c48:	892a                	mv	s2,a0
    80003c4a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003c4c:	0001c497          	auipc	s1,0x1c
    80003c50:	34c48493          	addi	s1,s1,844 # 8001ff98 <log>
    80003c54:	00004597          	auipc	a1,0x4
    80003c58:	8ec58593          	addi	a1,a1,-1812 # 80007540 <etext+0x540>
    80003c5c:	8526                	mv	a0,s1
    80003c5e:	ef1fc0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    80003c62:	0149a583          	lw	a1,20(s3)
    80003c66:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003c68:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003c6c:	854a                	mv	a0,s2
    80003c6e:	f95fe0ef          	jal	80002c02 <bread>
  log.lh.n = lh->n;
    80003c72:	4d30                	lw	a2,88(a0)
    80003c74:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003c76:	00c05f63          	blez	a2,80003c94 <initlog+0x5a>
    80003c7a:	87aa                	mv	a5,a0
    80003c7c:	0001c717          	auipc	a4,0x1c
    80003c80:	34870713          	addi	a4,a4,840 # 8001ffc4 <log+0x2c>
    80003c84:	060a                	slli	a2,a2,0x2
    80003c86:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003c88:	4ff4                	lw	a3,92(a5)
    80003c8a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003c8c:	0791                	addi	a5,a5,4
    80003c8e:	0711                	addi	a4,a4,4
    80003c90:	fec79ce3          	bne	a5,a2,80003c88 <initlog+0x4e>
  brelse(buf);
    80003c94:	876ff0ef          	jal	80002d0a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003c98:	4505                	li	a0,1
    80003c9a:	edbff0ef          	jal	80003b74 <install_trans>
  log.lh.n = 0;
    80003c9e:	0001c797          	auipc	a5,0x1c
    80003ca2:	3207a123          	sw	zero,802(a5) # 8001ffc0 <log+0x28>
  write_head(); // clear the log
    80003ca6:	e71ff0ef          	jal	80003b16 <write_head>
}
    80003caa:	70a2                	ld	ra,40(sp)
    80003cac:	7402                	ld	s0,32(sp)
    80003cae:	64e2                	ld	s1,24(sp)
    80003cb0:	6942                	ld	s2,16(sp)
    80003cb2:	69a2                	ld	s3,8(sp)
    80003cb4:	6145                	addi	sp,sp,48
    80003cb6:	8082                	ret

0000000080003cb8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003cb8:	1101                	addi	sp,sp,-32
    80003cba:	ec06                	sd	ra,24(sp)
    80003cbc:	e822                	sd	s0,16(sp)
    80003cbe:	e426                	sd	s1,8(sp)
    80003cc0:	e04a                	sd	s2,0(sp)
    80003cc2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003cc4:	0001c517          	auipc	a0,0x1c
    80003cc8:	2d450513          	addi	a0,a0,724 # 8001ff98 <log>
    80003ccc:	f03fc0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    80003cd0:	0001c497          	auipc	s1,0x1c
    80003cd4:	2c848493          	addi	s1,s1,712 # 8001ff98 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003cd8:	4979                	li	s2,30
    80003cda:	a029                	j	80003ce4 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003cdc:	85a6                	mv	a1,s1
    80003cde:	8526                	mv	a0,s1
    80003ce0:	aa6fe0ef          	jal	80001f86 <sleep>
    if(log.committing){
    80003ce4:	509c                	lw	a5,32(s1)
    80003ce6:	fbfd                	bnez	a5,80003cdc <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003ce8:	4cd8                	lw	a4,28(s1)
    80003cea:	2705                	addiw	a4,a4,1
    80003cec:	0027179b          	slliw	a5,a4,0x2
    80003cf0:	9fb9                	addw	a5,a5,a4
    80003cf2:	0017979b          	slliw	a5,a5,0x1
    80003cf6:	5494                	lw	a3,40(s1)
    80003cf8:	9fb5                	addw	a5,a5,a3
    80003cfa:	00f95763          	bge	s2,a5,80003d08 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003cfe:	85a6                	mv	a1,s1
    80003d00:	8526                	mv	a0,s1
    80003d02:	a84fe0ef          	jal	80001f86 <sleep>
    80003d06:	bff9                	j	80003ce4 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003d08:	0001c517          	auipc	a0,0x1c
    80003d0c:	29050513          	addi	a0,a0,656 # 8001ff98 <log>
    80003d10:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003d12:	f55fc0ef          	jal	80000c66 <release>
      break;
    }
  }
}
    80003d16:	60e2                	ld	ra,24(sp)
    80003d18:	6442                	ld	s0,16(sp)
    80003d1a:	64a2                	ld	s1,8(sp)
    80003d1c:	6902                	ld	s2,0(sp)
    80003d1e:	6105                	addi	sp,sp,32
    80003d20:	8082                	ret

0000000080003d22 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003d22:	7139                	addi	sp,sp,-64
    80003d24:	fc06                	sd	ra,56(sp)
    80003d26:	f822                	sd	s0,48(sp)
    80003d28:	f426                	sd	s1,40(sp)
    80003d2a:	f04a                	sd	s2,32(sp)
    80003d2c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003d2e:	0001c497          	auipc	s1,0x1c
    80003d32:	26a48493          	addi	s1,s1,618 # 8001ff98 <log>
    80003d36:	8526                	mv	a0,s1
    80003d38:	e97fc0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    80003d3c:	4cdc                	lw	a5,28(s1)
    80003d3e:	37fd                	addiw	a5,a5,-1
    80003d40:	0007891b          	sext.w	s2,a5
    80003d44:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003d46:	509c                	lw	a5,32(s1)
    80003d48:	ef9d                	bnez	a5,80003d86 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80003d4a:	04091763          	bnez	s2,80003d98 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003d4e:	0001c497          	auipc	s1,0x1c
    80003d52:	24a48493          	addi	s1,s1,586 # 8001ff98 <log>
    80003d56:	4785                	li	a5,1
    80003d58:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003d5a:	8526                	mv	a0,s1
    80003d5c:	f0bfc0ef          	jal	80000c66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003d60:	549c                	lw	a5,40(s1)
    80003d62:	04f04b63          	bgtz	a5,80003db8 <end_op+0x96>
    acquire(&log.lock);
    80003d66:	0001c497          	auipc	s1,0x1c
    80003d6a:	23248493          	addi	s1,s1,562 # 8001ff98 <log>
    80003d6e:	8526                	mv	a0,s1
    80003d70:	e5ffc0ef          	jal	80000bce <acquire>
    log.committing = 0;
    80003d74:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003d78:	8526                	mv	a0,s1
    80003d7a:	a58fe0ef          	jal	80001fd2 <wakeup>
    release(&log.lock);
    80003d7e:	8526                	mv	a0,s1
    80003d80:	ee7fc0ef          	jal	80000c66 <release>
}
    80003d84:	a025                	j	80003dac <end_op+0x8a>
    80003d86:	ec4e                	sd	s3,24(sp)
    80003d88:	e852                	sd	s4,16(sp)
    80003d8a:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80003d8c:	00003517          	auipc	a0,0x3
    80003d90:	7bc50513          	addi	a0,a0,1980 # 80007548 <etext+0x548>
    80003d94:	a4dfc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80003d98:	0001c497          	auipc	s1,0x1c
    80003d9c:	20048493          	addi	s1,s1,512 # 8001ff98 <log>
    80003da0:	8526                	mv	a0,s1
    80003da2:	a30fe0ef          	jal	80001fd2 <wakeup>
  release(&log.lock);
    80003da6:	8526                	mv	a0,s1
    80003da8:	ebffc0ef          	jal	80000c66 <release>
}
    80003dac:	70e2                	ld	ra,56(sp)
    80003dae:	7442                	ld	s0,48(sp)
    80003db0:	74a2                	ld	s1,40(sp)
    80003db2:	7902                	ld	s2,32(sp)
    80003db4:	6121                	addi	sp,sp,64
    80003db6:	8082                	ret
    80003db8:	ec4e                	sd	s3,24(sp)
    80003dba:	e852                	sd	s4,16(sp)
    80003dbc:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80003dbe:	0001ca97          	auipc	s5,0x1c
    80003dc2:	206a8a93          	addi	s5,s5,518 # 8001ffc4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003dc6:	0001ca17          	auipc	s4,0x1c
    80003dca:	1d2a0a13          	addi	s4,s4,466 # 8001ff98 <log>
    80003dce:	018a2583          	lw	a1,24(s4)
    80003dd2:	012585bb          	addw	a1,a1,s2
    80003dd6:	2585                	addiw	a1,a1,1
    80003dd8:	024a2503          	lw	a0,36(s4)
    80003ddc:	e27fe0ef          	jal	80002c02 <bread>
    80003de0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003de2:	000aa583          	lw	a1,0(s5)
    80003de6:	024a2503          	lw	a0,36(s4)
    80003dea:	e19fe0ef          	jal	80002c02 <bread>
    80003dee:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003df0:	40000613          	li	a2,1024
    80003df4:	05850593          	addi	a1,a0,88
    80003df8:	05848513          	addi	a0,s1,88
    80003dfc:	f03fc0ef          	jal	80000cfe <memmove>
    bwrite(to);  // write the log
    80003e00:	8526                	mv	a0,s1
    80003e02:	ed7fe0ef          	jal	80002cd8 <bwrite>
    brelse(from);
    80003e06:	854e                	mv	a0,s3
    80003e08:	f03fe0ef          	jal	80002d0a <brelse>
    brelse(to);
    80003e0c:	8526                	mv	a0,s1
    80003e0e:	efdfe0ef          	jal	80002d0a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e12:	2905                	addiw	s2,s2,1
    80003e14:	0a91                	addi	s5,s5,4
    80003e16:	028a2783          	lw	a5,40(s4)
    80003e1a:	faf94ae3          	blt	s2,a5,80003dce <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003e1e:	cf9ff0ef          	jal	80003b16 <write_head>
    install_trans(0); // Now install writes to home locations
    80003e22:	4501                	li	a0,0
    80003e24:	d51ff0ef          	jal	80003b74 <install_trans>
    log.lh.n = 0;
    80003e28:	0001c797          	auipc	a5,0x1c
    80003e2c:	1807ac23          	sw	zero,408(a5) # 8001ffc0 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003e30:	ce7ff0ef          	jal	80003b16 <write_head>
    80003e34:	69e2                	ld	s3,24(sp)
    80003e36:	6a42                	ld	s4,16(sp)
    80003e38:	6aa2                	ld	s5,8(sp)
    80003e3a:	b735                	j	80003d66 <end_op+0x44>

0000000080003e3c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003e3c:	1101                	addi	sp,sp,-32
    80003e3e:	ec06                	sd	ra,24(sp)
    80003e40:	e822                	sd	s0,16(sp)
    80003e42:	e426                	sd	s1,8(sp)
    80003e44:	e04a                	sd	s2,0(sp)
    80003e46:	1000                	addi	s0,sp,32
    80003e48:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003e4a:	0001c917          	auipc	s2,0x1c
    80003e4e:	14e90913          	addi	s2,s2,334 # 8001ff98 <log>
    80003e52:	854a                	mv	a0,s2
    80003e54:	d7bfc0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003e58:	02892603          	lw	a2,40(s2)
    80003e5c:	47f5                	li	a5,29
    80003e5e:	04c7cc63          	blt	a5,a2,80003eb6 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003e62:	0001c797          	auipc	a5,0x1c
    80003e66:	1527a783          	lw	a5,338(a5) # 8001ffb4 <log+0x1c>
    80003e6a:	04f05c63          	blez	a5,80003ec2 <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003e6e:	4781                	li	a5,0
    80003e70:	04c05f63          	blez	a2,80003ece <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003e74:	44cc                	lw	a1,12(s1)
    80003e76:	0001c717          	auipc	a4,0x1c
    80003e7a:	14e70713          	addi	a4,a4,334 # 8001ffc4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003e7e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003e80:	4314                	lw	a3,0(a4)
    80003e82:	04b68663          	beq	a3,a1,80003ece <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003e86:	2785                	addiw	a5,a5,1
    80003e88:	0711                	addi	a4,a4,4
    80003e8a:	fef61be3          	bne	a2,a5,80003e80 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003e8e:	0621                	addi	a2,a2,8
    80003e90:	060a                	slli	a2,a2,0x2
    80003e92:	0001c797          	auipc	a5,0x1c
    80003e96:	10678793          	addi	a5,a5,262 # 8001ff98 <log>
    80003e9a:	97b2                	add	a5,a5,a2
    80003e9c:	44d8                	lw	a4,12(s1)
    80003e9e:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003ea0:	8526                	mv	a0,s1
    80003ea2:	ef1fe0ef          	jal	80002d92 <bpin>
    log.lh.n++;
    80003ea6:	0001c717          	auipc	a4,0x1c
    80003eaa:	0f270713          	addi	a4,a4,242 # 8001ff98 <log>
    80003eae:	571c                	lw	a5,40(a4)
    80003eb0:	2785                	addiw	a5,a5,1
    80003eb2:	d71c                	sw	a5,40(a4)
    80003eb4:	a80d                	j	80003ee6 <log_write+0xaa>
    panic("too big a transaction");
    80003eb6:	00003517          	auipc	a0,0x3
    80003eba:	6a250513          	addi	a0,a0,1698 # 80007558 <etext+0x558>
    80003ebe:	923fc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    80003ec2:	00003517          	auipc	a0,0x3
    80003ec6:	6ae50513          	addi	a0,a0,1710 # 80007570 <etext+0x570>
    80003eca:	917fc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    80003ece:	00878693          	addi	a3,a5,8
    80003ed2:	068a                	slli	a3,a3,0x2
    80003ed4:	0001c717          	auipc	a4,0x1c
    80003ed8:	0c470713          	addi	a4,a4,196 # 8001ff98 <log>
    80003edc:	9736                	add	a4,a4,a3
    80003ede:	44d4                	lw	a3,12(s1)
    80003ee0:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003ee2:	faf60fe3          	beq	a2,a5,80003ea0 <log_write+0x64>
  }
  release(&log.lock);
    80003ee6:	0001c517          	auipc	a0,0x1c
    80003eea:	0b250513          	addi	a0,a0,178 # 8001ff98 <log>
    80003eee:	d79fc0ef          	jal	80000c66 <release>
}
    80003ef2:	60e2                	ld	ra,24(sp)
    80003ef4:	6442                	ld	s0,16(sp)
    80003ef6:	64a2                	ld	s1,8(sp)
    80003ef8:	6902                	ld	s2,0(sp)
    80003efa:	6105                	addi	sp,sp,32
    80003efc:	8082                	ret

0000000080003efe <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003efe:	1101                	addi	sp,sp,-32
    80003f00:	ec06                	sd	ra,24(sp)
    80003f02:	e822                	sd	s0,16(sp)
    80003f04:	e426                	sd	s1,8(sp)
    80003f06:	e04a                	sd	s2,0(sp)
    80003f08:	1000                	addi	s0,sp,32
    80003f0a:	84aa                	mv	s1,a0
    80003f0c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003f0e:	00003597          	auipc	a1,0x3
    80003f12:	68258593          	addi	a1,a1,1666 # 80007590 <etext+0x590>
    80003f16:	0521                	addi	a0,a0,8
    80003f18:	c37fc0ef          	jal	80000b4e <initlock>
  lk->name = name;
    80003f1c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003f20:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003f24:	0204a423          	sw	zero,40(s1)
}
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6902                	ld	s2,0(sp)
    80003f30:	6105                	addi	sp,sp,32
    80003f32:	8082                	ret

0000000080003f34 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003f34:	1101                	addi	sp,sp,-32
    80003f36:	ec06                	sd	ra,24(sp)
    80003f38:	e822                	sd	s0,16(sp)
    80003f3a:	e426                	sd	s1,8(sp)
    80003f3c:	e04a                	sd	s2,0(sp)
    80003f3e:	1000                	addi	s0,sp,32
    80003f40:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003f42:	00850913          	addi	s2,a0,8
    80003f46:	854a                	mv	a0,s2
    80003f48:	c87fc0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    80003f4c:	409c                	lw	a5,0(s1)
    80003f4e:	c799                	beqz	a5,80003f5c <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003f50:	85ca                	mv	a1,s2
    80003f52:	8526                	mv	a0,s1
    80003f54:	832fe0ef          	jal	80001f86 <sleep>
  while (lk->locked) {
    80003f58:	409c                	lw	a5,0(s1)
    80003f5a:	fbfd                	bnez	a5,80003f50 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003f5c:	4785                	li	a5,1
    80003f5e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003f60:	96ffd0ef          	jal	800018ce <myproc>
    80003f64:	591c                	lw	a5,48(a0)
    80003f66:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003f68:	854a                	mv	a0,s2
    80003f6a:	cfdfc0ef          	jal	80000c66 <release>
}
    80003f6e:	60e2                	ld	ra,24(sp)
    80003f70:	6442                	ld	s0,16(sp)
    80003f72:	64a2                	ld	s1,8(sp)
    80003f74:	6902                	ld	s2,0(sp)
    80003f76:	6105                	addi	sp,sp,32
    80003f78:	8082                	ret

0000000080003f7a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003f7a:	1101                	addi	sp,sp,-32
    80003f7c:	ec06                	sd	ra,24(sp)
    80003f7e:	e822                	sd	s0,16(sp)
    80003f80:	e426                	sd	s1,8(sp)
    80003f82:	e04a                	sd	s2,0(sp)
    80003f84:	1000                	addi	s0,sp,32
    80003f86:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003f88:	00850913          	addi	s2,a0,8
    80003f8c:	854a                	mv	a0,s2
    80003f8e:	c41fc0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    80003f92:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003f96:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	836fe0ef          	jal	80001fd2 <wakeup>
  release(&lk->lk);
    80003fa0:	854a                	mv	a0,s2
    80003fa2:	cc5fc0ef          	jal	80000c66 <release>
}
    80003fa6:	60e2                	ld	ra,24(sp)
    80003fa8:	6442                	ld	s0,16(sp)
    80003faa:	64a2                	ld	s1,8(sp)
    80003fac:	6902                	ld	s2,0(sp)
    80003fae:	6105                	addi	sp,sp,32
    80003fb0:	8082                	ret

0000000080003fb2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003fb2:	7179                	addi	sp,sp,-48
    80003fb4:	f406                	sd	ra,40(sp)
    80003fb6:	f022                	sd	s0,32(sp)
    80003fb8:	ec26                	sd	s1,24(sp)
    80003fba:	e84a                	sd	s2,16(sp)
    80003fbc:	1800                	addi	s0,sp,48
    80003fbe:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003fc0:	00850913          	addi	s2,a0,8
    80003fc4:	854a                	mv	a0,s2
    80003fc6:	c09fc0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003fca:	409c                	lw	a5,0(s1)
    80003fcc:	ef81                	bnez	a5,80003fe4 <holdingsleep+0x32>
    80003fce:	4481                	li	s1,0
  release(&lk->lk);
    80003fd0:	854a                	mv	a0,s2
    80003fd2:	c95fc0ef          	jal	80000c66 <release>
  return r;
}
    80003fd6:	8526                	mv	a0,s1
    80003fd8:	70a2                	ld	ra,40(sp)
    80003fda:	7402                	ld	s0,32(sp)
    80003fdc:	64e2                	ld	s1,24(sp)
    80003fde:	6942                	ld	s2,16(sp)
    80003fe0:	6145                	addi	sp,sp,48
    80003fe2:	8082                	ret
    80003fe4:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80003fe6:	0284a983          	lw	s3,40(s1)
    80003fea:	8e5fd0ef          	jal	800018ce <myproc>
    80003fee:	5904                	lw	s1,48(a0)
    80003ff0:	413484b3          	sub	s1,s1,s3
    80003ff4:	0014b493          	seqz	s1,s1
    80003ff8:	69a2                	ld	s3,8(sp)
    80003ffa:	bfd9                	j	80003fd0 <holdingsleep+0x1e>

0000000080003ffc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80003ffc:	1141                	addi	sp,sp,-16
    80003ffe:	e406                	sd	ra,8(sp)
    80004000:	e022                	sd	s0,0(sp)
    80004002:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004004:	00003597          	auipc	a1,0x3
    80004008:	59c58593          	addi	a1,a1,1436 # 800075a0 <etext+0x5a0>
    8000400c:	0001c517          	auipc	a0,0x1c
    80004010:	0d450513          	addi	a0,a0,212 # 800200e0 <ftable>
    80004014:	b3bfc0ef          	jal	80000b4e <initlock>
}
    80004018:	60a2                	ld	ra,8(sp)
    8000401a:	6402                	ld	s0,0(sp)
    8000401c:	0141                	addi	sp,sp,16
    8000401e:	8082                	ret

0000000080004020 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004020:	1101                	addi	sp,sp,-32
    80004022:	ec06                	sd	ra,24(sp)
    80004024:	e822                	sd	s0,16(sp)
    80004026:	e426                	sd	s1,8(sp)
    80004028:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000402a:	0001c517          	auipc	a0,0x1c
    8000402e:	0b650513          	addi	a0,a0,182 # 800200e0 <ftable>
    80004032:	b9dfc0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004036:	0001c497          	auipc	s1,0x1c
    8000403a:	0c248493          	addi	s1,s1,194 # 800200f8 <ftable+0x18>
    8000403e:	0001d717          	auipc	a4,0x1d
    80004042:	05a70713          	addi	a4,a4,90 # 80021098 <disk>
    if(f->ref == 0){
    80004046:	40dc                	lw	a5,4(s1)
    80004048:	cf89                	beqz	a5,80004062 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000404a:	02848493          	addi	s1,s1,40
    8000404e:	fee49ce3          	bne	s1,a4,80004046 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004052:	0001c517          	auipc	a0,0x1c
    80004056:	08e50513          	addi	a0,a0,142 # 800200e0 <ftable>
    8000405a:	c0dfc0ef          	jal	80000c66 <release>
  return 0;
    8000405e:	4481                	li	s1,0
    80004060:	a809                	j	80004072 <filealloc+0x52>
      f->ref = 1;
    80004062:	4785                	li	a5,1
    80004064:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004066:	0001c517          	auipc	a0,0x1c
    8000406a:	07a50513          	addi	a0,a0,122 # 800200e0 <ftable>
    8000406e:	bf9fc0ef          	jal	80000c66 <release>
}
    80004072:	8526                	mv	a0,s1
    80004074:	60e2                	ld	ra,24(sp)
    80004076:	6442                	ld	s0,16(sp)
    80004078:	64a2                	ld	s1,8(sp)
    8000407a:	6105                	addi	sp,sp,32
    8000407c:	8082                	ret

000000008000407e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000407e:	1101                	addi	sp,sp,-32
    80004080:	ec06                	sd	ra,24(sp)
    80004082:	e822                	sd	s0,16(sp)
    80004084:	e426                	sd	s1,8(sp)
    80004086:	1000                	addi	s0,sp,32
    80004088:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000408a:	0001c517          	auipc	a0,0x1c
    8000408e:	05650513          	addi	a0,a0,86 # 800200e0 <ftable>
    80004092:	b3dfc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80004096:	40dc                	lw	a5,4(s1)
    80004098:	02f05063          	blez	a5,800040b8 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    8000409c:	2785                	addiw	a5,a5,1
    8000409e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800040a0:	0001c517          	auipc	a0,0x1c
    800040a4:	04050513          	addi	a0,a0,64 # 800200e0 <ftable>
    800040a8:	bbffc0ef          	jal	80000c66 <release>
  return f;
}
    800040ac:	8526                	mv	a0,s1
    800040ae:	60e2                	ld	ra,24(sp)
    800040b0:	6442                	ld	s0,16(sp)
    800040b2:	64a2                	ld	s1,8(sp)
    800040b4:	6105                	addi	sp,sp,32
    800040b6:	8082                	ret
    panic("filedup");
    800040b8:	00003517          	auipc	a0,0x3
    800040bc:	4f050513          	addi	a0,a0,1264 # 800075a8 <etext+0x5a8>
    800040c0:	f20fc0ef          	jal	800007e0 <panic>

00000000800040c4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800040c4:	7139                	addi	sp,sp,-64
    800040c6:	fc06                	sd	ra,56(sp)
    800040c8:	f822                	sd	s0,48(sp)
    800040ca:	f426                	sd	s1,40(sp)
    800040cc:	0080                	addi	s0,sp,64
    800040ce:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800040d0:	0001c517          	auipc	a0,0x1c
    800040d4:	01050513          	addi	a0,a0,16 # 800200e0 <ftable>
    800040d8:	af7fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    800040dc:	40dc                	lw	a5,4(s1)
    800040de:	04f05a63          	blez	a5,80004132 <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    800040e2:	37fd                	addiw	a5,a5,-1
    800040e4:	0007871b          	sext.w	a4,a5
    800040e8:	c0dc                	sw	a5,4(s1)
    800040ea:	04e04e63          	bgtz	a4,80004146 <fileclose+0x82>
    800040ee:	f04a                	sd	s2,32(sp)
    800040f0:	ec4e                	sd	s3,24(sp)
    800040f2:	e852                	sd	s4,16(sp)
    800040f4:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800040f6:	0004a903          	lw	s2,0(s1)
    800040fa:	0094ca83          	lbu	s5,9(s1)
    800040fe:	0104ba03          	ld	s4,16(s1)
    80004102:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004106:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000410a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000410e:	0001c517          	auipc	a0,0x1c
    80004112:	fd250513          	addi	a0,a0,-46 # 800200e0 <ftable>
    80004116:	b51fc0ef          	jal	80000c66 <release>

  if(ff.type == FD_PIPE){
    8000411a:	4785                	li	a5,1
    8000411c:	04f90063          	beq	s2,a5,8000415c <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004120:	3979                	addiw	s2,s2,-2
    80004122:	4785                	li	a5,1
    80004124:	0527f563          	bgeu	a5,s2,8000416e <fileclose+0xaa>
    80004128:	7902                	ld	s2,32(sp)
    8000412a:	69e2                	ld	s3,24(sp)
    8000412c:	6a42                	ld	s4,16(sp)
    8000412e:	6aa2                	ld	s5,8(sp)
    80004130:	a00d                	j	80004152 <fileclose+0x8e>
    80004132:	f04a                	sd	s2,32(sp)
    80004134:	ec4e                	sd	s3,24(sp)
    80004136:	e852                	sd	s4,16(sp)
    80004138:	e456                	sd	s5,8(sp)
    panic("fileclose");
    8000413a:	00003517          	auipc	a0,0x3
    8000413e:	47650513          	addi	a0,a0,1142 # 800075b0 <etext+0x5b0>
    80004142:	e9efc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    80004146:	0001c517          	auipc	a0,0x1c
    8000414a:	f9a50513          	addi	a0,a0,-102 # 800200e0 <ftable>
    8000414e:	b19fc0ef          	jal	80000c66 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80004152:	70e2                	ld	ra,56(sp)
    80004154:	7442                	ld	s0,48(sp)
    80004156:	74a2                	ld	s1,40(sp)
    80004158:	6121                	addi	sp,sp,64
    8000415a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000415c:	85d6                	mv	a1,s5
    8000415e:	8552                	mv	a0,s4
    80004160:	336000ef          	jal	80004496 <pipeclose>
    80004164:	7902                	ld	s2,32(sp)
    80004166:	69e2                	ld	s3,24(sp)
    80004168:	6a42                	ld	s4,16(sp)
    8000416a:	6aa2                	ld	s5,8(sp)
    8000416c:	b7dd                	j	80004152 <fileclose+0x8e>
    begin_op();
    8000416e:	b4bff0ef          	jal	80003cb8 <begin_op>
    iput(ff.ip);
    80004172:	854e                	mv	a0,s3
    80004174:	adcff0ef          	jal	80003450 <iput>
    end_op();
    80004178:	babff0ef          	jal	80003d22 <end_op>
    8000417c:	7902                	ld	s2,32(sp)
    8000417e:	69e2                	ld	s3,24(sp)
    80004180:	6a42                	ld	s4,16(sp)
    80004182:	6aa2                	ld	s5,8(sp)
    80004184:	b7f9                	j	80004152 <fileclose+0x8e>

0000000080004186 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004186:	715d                	addi	sp,sp,-80
    80004188:	e486                	sd	ra,72(sp)
    8000418a:	e0a2                	sd	s0,64(sp)
    8000418c:	fc26                	sd	s1,56(sp)
    8000418e:	f44e                	sd	s3,40(sp)
    80004190:	0880                	addi	s0,sp,80
    80004192:	84aa                	mv	s1,a0
    80004194:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004196:	f38fd0ef          	jal	800018ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000419a:	409c                	lw	a5,0(s1)
    8000419c:	37f9                	addiw	a5,a5,-2
    8000419e:	4705                	li	a4,1
    800041a0:	04f76063          	bltu	a4,a5,800041e0 <filestat+0x5a>
    800041a4:	f84a                	sd	s2,48(sp)
    800041a6:	892a                	mv	s2,a0
    ilock(f->ip);
    800041a8:	6c88                	ld	a0,24(s1)
    800041aa:	924ff0ef          	jal	800032ce <ilock>
    stati(f->ip, &st);
    800041ae:	fb840593          	addi	a1,s0,-72
    800041b2:	6c88                	ld	a0,24(s1)
    800041b4:	c80ff0ef          	jal	80003634 <stati>
    iunlock(f->ip);
    800041b8:	6c88                	ld	a0,24(s1)
    800041ba:	9c2ff0ef          	jal	8000337c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800041be:	46e1                	li	a3,24
    800041c0:	fb840613          	addi	a2,s0,-72
    800041c4:	85ce                	mv	a1,s3
    800041c6:	06893503          	ld	a0,104(s2)
    800041ca:	c18fd0ef          	jal	800015e2 <copyout>
    800041ce:	41f5551b          	sraiw	a0,a0,0x1f
    800041d2:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    800041d4:	60a6                	ld	ra,72(sp)
    800041d6:	6406                	ld	s0,64(sp)
    800041d8:	74e2                	ld	s1,56(sp)
    800041da:	79a2                	ld	s3,40(sp)
    800041dc:	6161                	addi	sp,sp,80
    800041de:	8082                	ret
  return -1;
    800041e0:	557d                	li	a0,-1
    800041e2:	bfcd                	j	800041d4 <filestat+0x4e>

00000000800041e4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800041e4:	7179                	addi	sp,sp,-48
    800041e6:	f406                	sd	ra,40(sp)
    800041e8:	f022                	sd	s0,32(sp)
    800041ea:	e84a                	sd	s2,16(sp)
    800041ec:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800041ee:	00854783          	lbu	a5,8(a0)
    800041f2:	cfd1                	beqz	a5,8000428e <fileread+0xaa>
    800041f4:	ec26                	sd	s1,24(sp)
    800041f6:	e44e                	sd	s3,8(sp)
    800041f8:	84aa                	mv	s1,a0
    800041fa:	89ae                	mv	s3,a1
    800041fc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800041fe:	411c                	lw	a5,0(a0)
    80004200:	4705                	li	a4,1
    80004202:	04e78363          	beq	a5,a4,80004248 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004206:	470d                	li	a4,3
    80004208:	04e78763          	beq	a5,a4,80004256 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000420c:	4709                	li	a4,2
    8000420e:	06e79a63          	bne	a5,a4,80004282 <fileread+0x9e>
    ilock(f->ip);
    80004212:	6d08                	ld	a0,24(a0)
    80004214:	8baff0ef          	jal	800032ce <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004218:	874a                	mv	a4,s2
    8000421a:	5094                	lw	a3,32(s1)
    8000421c:	864e                	mv	a2,s3
    8000421e:	4585                	li	a1,1
    80004220:	6c88                	ld	a0,24(s1)
    80004222:	c3cff0ef          	jal	8000365e <readi>
    80004226:	892a                	mv	s2,a0
    80004228:	00a05563          	blez	a0,80004232 <fileread+0x4e>
      f->off += r;
    8000422c:	509c                	lw	a5,32(s1)
    8000422e:	9fa9                	addw	a5,a5,a0
    80004230:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004232:	6c88                	ld	a0,24(s1)
    80004234:	948ff0ef          	jal	8000337c <iunlock>
    80004238:	64e2                	ld	s1,24(sp)
    8000423a:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    8000423c:	854a                	mv	a0,s2
    8000423e:	70a2                	ld	ra,40(sp)
    80004240:	7402                	ld	s0,32(sp)
    80004242:	6942                	ld	s2,16(sp)
    80004244:	6145                	addi	sp,sp,48
    80004246:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004248:	6908                	ld	a0,16(a0)
    8000424a:	388000ef          	jal	800045d2 <piperead>
    8000424e:	892a                	mv	s2,a0
    80004250:	64e2                	ld	s1,24(sp)
    80004252:	69a2                	ld	s3,8(sp)
    80004254:	b7e5                	j	8000423c <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004256:	02451783          	lh	a5,36(a0)
    8000425a:	03079693          	slli	a3,a5,0x30
    8000425e:	92c1                	srli	a3,a3,0x30
    80004260:	4725                	li	a4,9
    80004262:	02d76863          	bltu	a4,a3,80004292 <fileread+0xae>
    80004266:	0792                	slli	a5,a5,0x4
    80004268:	0001c717          	auipc	a4,0x1c
    8000426c:	dd870713          	addi	a4,a4,-552 # 80020040 <devsw>
    80004270:	97ba                	add	a5,a5,a4
    80004272:	639c                	ld	a5,0(a5)
    80004274:	c39d                	beqz	a5,8000429a <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    80004276:	4505                	li	a0,1
    80004278:	9782                	jalr	a5
    8000427a:	892a                	mv	s2,a0
    8000427c:	64e2                	ld	s1,24(sp)
    8000427e:	69a2                	ld	s3,8(sp)
    80004280:	bf75                	j	8000423c <fileread+0x58>
    panic("fileread");
    80004282:	00003517          	auipc	a0,0x3
    80004286:	33e50513          	addi	a0,a0,830 # 800075c0 <etext+0x5c0>
    8000428a:	d56fc0ef          	jal	800007e0 <panic>
    return -1;
    8000428e:	597d                	li	s2,-1
    80004290:	b775                	j	8000423c <fileread+0x58>
      return -1;
    80004292:	597d                	li	s2,-1
    80004294:	64e2                	ld	s1,24(sp)
    80004296:	69a2                	ld	s3,8(sp)
    80004298:	b755                	j	8000423c <fileread+0x58>
    8000429a:	597d                	li	s2,-1
    8000429c:	64e2                	ld	s1,24(sp)
    8000429e:	69a2                	ld	s3,8(sp)
    800042a0:	bf71                	j	8000423c <fileread+0x58>

00000000800042a2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800042a2:	00954783          	lbu	a5,9(a0)
    800042a6:	10078b63          	beqz	a5,800043bc <filewrite+0x11a>
{
    800042aa:	715d                	addi	sp,sp,-80
    800042ac:	e486                	sd	ra,72(sp)
    800042ae:	e0a2                	sd	s0,64(sp)
    800042b0:	f84a                	sd	s2,48(sp)
    800042b2:	f052                	sd	s4,32(sp)
    800042b4:	e85a                	sd	s6,16(sp)
    800042b6:	0880                	addi	s0,sp,80
    800042b8:	892a                	mv	s2,a0
    800042ba:	8b2e                	mv	s6,a1
    800042bc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800042be:	411c                	lw	a5,0(a0)
    800042c0:	4705                	li	a4,1
    800042c2:	02e78763          	beq	a5,a4,800042f0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800042c6:	470d                	li	a4,3
    800042c8:	02e78863          	beq	a5,a4,800042f8 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800042cc:	4709                	li	a4,2
    800042ce:	0ce79c63          	bne	a5,a4,800043a6 <filewrite+0x104>
    800042d2:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800042d4:	0ac05863          	blez	a2,80004384 <filewrite+0xe2>
    800042d8:	fc26                	sd	s1,56(sp)
    800042da:	ec56                	sd	s5,24(sp)
    800042dc:	e45e                	sd	s7,8(sp)
    800042de:	e062                	sd	s8,0(sp)
    int i = 0;
    800042e0:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800042e2:	6b85                	lui	s7,0x1
    800042e4:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800042e8:	6c05                	lui	s8,0x1
    800042ea:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800042ee:	a8b5                	j	8000436a <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    800042f0:	6908                	ld	a0,16(a0)
    800042f2:	1fc000ef          	jal	800044ee <pipewrite>
    800042f6:	a04d                	j	80004398 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800042f8:	02451783          	lh	a5,36(a0)
    800042fc:	03079693          	slli	a3,a5,0x30
    80004300:	92c1                	srli	a3,a3,0x30
    80004302:	4725                	li	a4,9
    80004304:	0ad76e63          	bltu	a4,a3,800043c0 <filewrite+0x11e>
    80004308:	0792                	slli	a5,a5,0x4
    8000430a:	0001c717          	auipc	a4,0x1c
    8000430e:	d3670713          	addi	a4,a4,-714 # 80020040 <devsw>
    80004312:	97ba                	add	a5,a5,a4
    80004314:	679c                	ld	a5,8(a5)
    80004316:	c7dd                	beqz	a5,800043c4 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    80004318:	4505                	li	a0,1
    8000431a:	9782                	jalr	a5
    8000431c:	a8b5                	j	80004398 <filewrite+0xf6>
      if(n1 > max)
    8000431e:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004322:	997ff0ef          	jal	80003cb8 <begin_op>
      ilock(f->ip);
    80004326:	01893503          	ld	a0,24(s2)
    8000432a:	fa5fe0ef          	jal	800032ce <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000432e:	8756                	mv	a4,s5
    80004330:	02092683          	lw	a3,32(s2)
    80004334:	01698633          	add	a2,s3,s6
    80004338:	4585                	li	a1,1
    8000433a:	01893503          	ld	a0,24(s2)
    8000433e:	c1cff0ef          	jal	8000375a <writei>
    80004342:	84aa                	mv	s1,a0
    80004344:	00a05763          	blez	a0,80004352 <filewrite+0xb0>
        f->off += r;
    80004348:	02092783          	lw	a5,32(s2)
    8000434c:	9fa9                	addw	a5,a5,a0
    8000434e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004352:	01893503          	ld	a0,24(s2)
    80004356:	826ff0ef          	jal	8000337c <iunlock>
      end_op();
    8000435a:	9c9ff0ef          	jal	80003d22 <end_op>

      if(r != n1){
    8000435e:	029a9563          	bne	s5,s1,80004388 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    80004362:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004366:	0149da63          	bge	s3,s4,8000437a <filewrite+0xd8>
      int n1 = n - i;
    8000436a:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000436e:	0004879b          	sext.w	a5,s1
    80004372:	fafbd6e3          	bge	s7,a5,8000431e <filewrite+0x7c>
    80004376:	84e2                	mv	s1,s8
    80004378:	b75d                	j	8000431e <filewrite+0x7c>
    8000437a:	74e2                	ld	s1,56(sp)
    8000437c:	6ae2                	ld	s5,24(sp)
    8000437e:	6ba2                	ld	s7,8(sp)
    80004380:	6c02                	ld	s8,0(sp)
    80004382:	a039                	j	80004390 <filewrite+0xee>
    int i = 0;
    80004384:	4981                	li	s3,0
    80004386:	a029                	j	80004390 <filewrite+0xee>
    80004388:	74e2                	ld	s1,56(sp)
    8000438a:	6ae2                	ld	s5,24(sp)
    8000438c:	6ba2                	ld	s7,8(sp)
    8000438e:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    80004390:	033a1c63          	bne	s4,s3,800043c8 <filewrite+0x126>
    80004394:	8552                	mv	a0,s4
    80004396:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004398:	60a6                	ld	ra,72(sp)
    8000439a:	6406                	ld	s0,64(sp)
    8000439c:	7942                	ld	s2,48(sp)
    8000439e:	7a02                	ld	s4,32(sp)
    800043a0:	6b42                	ld	s6,16(sp)
    800043a2:	6161                	addi	sp,sp,80
    800043a4:	8082                	ret
    800043a6:	fc26                	sd	s1,56(sp)
    800043a8:	f44e                	sd	s3,40(sp)
    800043aa:	ec56                	sd	s5,24(sp)
    800043ac:	e45e                	sd	s7,8(sp)
    800043ae:	e062                	sd	s8,0(sp)
    panic("filewrite");
    800043b0:	00003517          	auipc	a0,0x3
    800043b4:	22050513          	addi	a0,a0,544 # 800075d0 <etext+0x5d0>
    800043b8:	c28fc0ef          	jal	800007e0 <panic>
    return -1;
    800043bc:	557d                	li	a0,-1
}
    800043be:	8082                	ret
      return -1;
    800043c0:	557d                	li	a0,-1
    800043c2:	bfd9                	j	80004398 <filewrite+0xf6>
    800043c4:	557d                	li	a0,-1
    800043c6:	bfc9                	j	80004398 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    800043c8:	557d                	li	a0,-1
    800043ca:	79a2                	ld	s3,40(sp)
    800043cc:	b7f1                	j	80004398 <filewrite+0xf6>

00000000800043ce <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800043ce:	7179                	addi	sp,sp,-48
    800043d0:	f406                	sd	ra,40(sp)
    800043d2:	f022                	sd	s0,32(sp)
    800043d4:	ec26                	sd	s1,24(sp)
    800043d6:	e052                	sd	s4,0(sp)
    800043d8:	1800                	addi	s0,sp,48
    800043da:	84aa                	mv	s1,a0
    800043dc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800043de:	0005b023          	sd	zero,0(a1)
    800043e2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800043e6:	c3bff0ef          	jal	80004020 <filealloc>
    800043ea:	e088                	sd	a0,0(s1)
    800043ec:	c549                	beqz	a0,80004476 <pipealloc+0xa8>
    800043ee:	c33ff0ef          	jal	80004020 <filealloc>
    800043f2:	00aa3023          	sd	a0,0(s4)
    800043f6:	cd25                	beqz	a0,8000446e <pipealloc+0xa0>
    800043f8:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800043fa:	f04fc0ef          	jal	80000afe <kalloc>
    800043fe:	892a                	mv	s2,a0
    80004400:	c12d                	beqz	a0,80004462 <pipealloc+0x94>
    80004402:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004404:	4985                	li	s3,1
    80004406:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000440a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000440e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004412:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004416:	00003597          	auipc	a1,0x3
    8000441a:	1ca58593          	addi	a1,a1,458 # 800075e0 <etext+0x5e0>
    8000441e:	f30fc0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    80004422:	609c                	ld	a5,0(s1)
    80004424:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004428:	609c                	ld	a5,0(s1)
    8000442a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000442e:	609c                	ld	a5,0(s1)
    80004430:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004434:	609c                	ld	a5,0(s1)
    80004436:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000443a:	000a3783          	ld	a5,0(s4)
    8000443e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004442:	000a3783          	ld	a5,0(s4)
    80004446:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000444a:	000a3783          	ld	a5,0(s4)
    8000444e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004452:	000a3783          	ld	a5,0(s4)
    80004456:	0127b823          	sd	s2,16(a5)
  return 0;
    8000445a:	4501                	li	a0,0
    8000445c:	6942                	ld	s2,16(sp)
    8000445e:	69a2                	ld	s3,8(sp)
    80004460:	a01d                	j	80004486 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004462:	6088                	ld	a0,0(s1)
    80004464:	c119                	beqz	a0,8000446a <pipealloc+0x9c>
    80004466:	6942                	ld	s2,16(sp)
    80004468:	a029                	j	80004472 <pipealloc+0xa4>
    8000446a:	6942                	ld	s2,16(sp)
    8000446c:	a029                	j	80004476 <pipealloc+0xa8>
    8000446e:	6088                	ld	a0,0(s1)
    80004470:	c10d                	beqz	a0,80004492 <pipealloc+0xc4>
    fileclose(*f0);
    80004472:	c53ff0ef          	jal	800040c4 <fileclose>
  if(*f1)
    80004476:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000447a:	557d                	li	a0,-1
  if(*f1)
    8000447c:	c789                	beqz	a5,80004486 <pipealloc+0xb8>
    fileclose(*f1);
    8000447e:	853e                	mv	a0,a5
    80004480:	c45ff0ef          	jal	800040c4 <fileclose>
  return -1;
    80004484:	557d                	li	a0,-1
}
    80004486:	70a2                	ld	ra,40(sp)
    80004488:	7402                	ld	s0,32(sp)
    8000448a:	64e2                	ld	s1,24(sp)
    8000448c:	6a02                	ld	s4,0(sp)
    8000448e:	6145                	addi	sp,sp,48
    80004490:	8082                	ret
  return -1;
    80004492:	557d                	li	a0,-1
    80004494:	bfcd                	j	80004486 <pipealloc+0xb8>

0000000080004496 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004496:	1101                	addi	sp,sp,-32
    80004498:	ec06                	sd	ra,24(sp)
    8000449a:	e822                	sd	s0,16(sp)
    8000449c:	e426                	sd	s1,8(sp)
    8000449e:	e04a                	sd	s2,0(sp)
    800044a0:	1000                	addi	s0,sp,32
    800044a2:	84aa                	mv	s1,a0
    800044a4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800044a6:	f28fc0ef          	jal	80000bce <acquire>
  if(writable){
    800044aa:	02090763          	beqz	s2,800044d8 <pipeclose+0x42>
    pi->writeopen = 0;
    800044ae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800044b2:	21848513          	addi	a0,s1,536
    800044b6:	b1dfd0ef          	jal	80001fd2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800044ba:	2204b783          	ld	a5,544(s1)
    800044be:	e785                	bnez	a5,800044e6 <pipeclose+0x50>
    release(&pi->lock);
    800044c0:	8526                	mv	a0,s1
    800044c2:	fa4fc0ef          	jal	80000c66 <release>
    kfree((char*)pi);
    800044c6:	8526                	mv	a0,s1
    800044c8:	d54fc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    800044cc:	60e2                	ld	ra,24(sp)
    800044ce:	6442                	ld	s0,16(sp)
    800044d0:	64a2                	ld	s1,8(sp)
    800044d2:	6902                	ld	s2,0(sp)
    800044d4:	6105                	addi	sp,sp,32
    800044d6:	8082                	ret
    pi->readopen = 0;
    800044d8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800044dc:	21c48513          	addi	a0,s1,540
    800044e0:	af3fd0ef          	jal	80001fd2 <wakeup>
    800044e4:	bfd9                	j	800044ba <pipeclose+0x24>
    release(&pi->lock);
    800044e6:	8526                	mv	a0,s1
    800044e8:	f7efc0ef          	jal	80000c66 <release>
}
    800044ec:	b7c5                	j	800044cc <pipeclose+0x36>

00000000800044ee <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800044ee:	711d                	addi	sp,sp,-96
    800044f0:	ec86                	sd	ra,88(sp)
    800044f2:	e8a2                	sd	s0,80(sp)
    800044f4:	e4a6                	sd	s1,72(sp)
    800044f6:	e0ca                	sd	s2,64(sp)
    800044f8:	fc4e                	sd	s3,56(sp)
    800044fa:	f852                	sd	s4,48(sp)
    800044fc:	f456                	sd	s5,40(sp)
    800044fe:	1080                	addi	s0,sp,96
    80004500:	84aa                	mv	s1,a0
    80004502:	8aae                	mv	s5,a1
    80004504:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004506:	bc8fd0ef          	jal	800018ce <myproc>
    8000450a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000450c:	8526                	mv	a0,s1
    8000450e:	ec0fc0ef          	jal	80000bce <acquire>
  while(i < n){
    80004512:	0b405a63          	blez	s4,800045c6 <pipewrite+0xd8>
    80004516:	f05a                	sd	s6,32(sp)
    80004518:	ec5e                	sd	s7,24(sp)
    8000451a:	e862                	sd	s8,16(sp)
  int i = 0;
    8000451c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000451e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004520:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004524:	21c48b93          	addi	s7,s1,540
    80004528:	a81d                	j	8000455e <pipewrite+0x70>
      release(&pi->lock);
    8000452a:	8526                	mv	a0,s1
    8000452c:	f3afc0ef          	jal	80000c66 <release>
      return -1;
    80004530:	597d                	li	s2,-1
    80004532:	7b02                	ld	s6,32(sp)
    80004534:	6be2                	ld	s7,24(sp)
    80004536:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004538:	854a                	mv	a0,s2
    8000453a:	60e6                	ld	ra,88(sp)
    8000453c:	6446                	ld	s0,80(sp)
    8000453e:	64a6                	ld	s1,72(sp)
    80004540:	6906                	ld	s2,64(sp)
    80004542:	79e2                	ld	s3,56(sp)
    80004544:	7a42                	ld	s4,48(sp)
    80004546:	7aa2                	ld	s5,40(sp)
    80004548:	6125                	addi	sp,sp,96
    8000454a:	8082                	ret
      wakeup(&pi->nread);
    8000454c:	8562                	mv	a0,s8
    8000454e:	a85fd0ef          	jal	80001fd2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004552:	85a6                	mv	a1,s1
    80004554:	855e                	mv	a0,s7
    80004556:	a31fd0ef          	jal	80001f86 <sleep>
  while(i < n){
    8000455a:	05495b63          	bge	s2,s4,800045b0 <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    8000455e:	2204a783          	lw	a5,544(s1)
    80004562:	d7e1                	beqz	a5,8000452a <pipewrite+0x3c>
    80004564:	854e                	mv	a0,s3
    80004566:	c61fd0ef          	jal	800021c6 <killed>
    8000456a:	f161                	bnez	a0,8000452a <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000456c:	2184a783          	lw	a5,536(s1)
    80004570:	21c4a703          	lw	a4,540(s1)
    80004574:	2007879b          	addiw	a5,a5,512
    80004578:	fcf70ae3          	beq	a4,a5,8000454c <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000457c:	4685                	li	a3,1
    8000457e:	01590633          	add	a2,s2,s5
    80004582:	faf40593          	addi	a1,s0,-81
    80004586:	0689b503          	ld	a0,104(s3)
    8000458a:	93cfd0ef          	jal	800016c6 <copyin>
    8000458e:	03650e63          	beq	a0,s6,800045ca <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004592:	21c4a783          	lw	a5,540(s1)
    80004596:	0017871b          	addiw	a4,a5,1
    8000459a:	20e4ae23          	sw	a4,540(s1)
    8000459e:	1ff7f793          	andi	a5,a5,511
    800045a2:	97a6                	add	a5,a5,s1
    800045a4:	faf44703          	lbu	a4,-81(s0)
    800045a8:	00e78c23          	sb	a4,24(a5)
      i++;
    800045ac:	2905                	addiw	s2,s2,1
    800045ae:	b775                	j	8000455a <pipewrite+0x6c>
    800045b0:	7b02                	ld	s6,32(sp)
    800045b2:	6be2                	ld	s7,24(sp)
    800045b4:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    800045b6:	21848513          	addi	a0,s1,536
    800045ba:	a19fd0ef          	jal	80001fd2 <wakeup>
  release(&pi->lock);
    800045be:	8526                	mv	a0,s1
    800045c0:	ea6fc0ef          	jal	80000c66 <release>
  return i;
    800045c4:	bf95                	j	80004538 <pipewrite+0x4a>
  int i = 0;
    800045c6:	4901                	li	s2,0
    800045c8:	b7fd                	j	800045b6 <pipewrite+0xc8>
    800045ca:	7b02                	ld	s6,32(sp)
    800045cc:	6be2                	ld	s7,24(sp)
    800045ce:	6c42                	ld	s8,16(sp)
    800045d0:	b7dd                	j	800045b6 <pipewrite+0xc8>

00000000800045d2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800045d2:	715d                	addi	sp,sp,-80
    800045d4:	e486                	sd	ra,72(sp)
    800045d6:	e0a2                	sd	s0,64(sp)
    800045d8:	fc26                	sd	s1,56(sp)
    800045da:	f84a                	sd	s2,48(sp)
    800045dc:	f44e                	sd	s3,40(sp)
    800045de:	f052                	sd	s4,32(sp)
    800045e0:	ec56                	sd	s5,24(sp)
    800045e2:	0880                	addi	s0,sp,80
    800045e4:	84aa                	mv	s1,a0
    800045e6:	892e                	mv	s2,a1
    800045e8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800045ea:	ae4fd0ef          	jal	800018ce <myproc>
    800045ee:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800045f0:	8526                	mv	a0,s1
    800045f2:	ddcfc0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800045f6:	2184a703          	lw	a4,536(s1)
    800045fa:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800045fe:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004602:	02f71563          	bne	a4,a5,8000462c <piperead+0x5a>
    80004606:	2244a783          	lw	a5,548(s1)
    8000460a:	cb85                	beqz	a5,8000463a <piperead+0x68>
    if(killed(pr)){
    8000460c:	8552                	mv	a0,s4
    8000460e:	bb9fd0ef          	jal	800021c6 <killed>
    80004612:	ed19                	bnez	a0,80004630 <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004614:	85a6                	mv	a1,s1
    80004616:	854e                	mv	a0,s3
    80004618:	96ffd0ef          	jal	80001f86 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000461c:	2184a703          	lw	a4,536(s1)
    80004620:	21c4a783          	lw	a5,540(s1)
    80004624:	fef701e3          	beq	a4,a5,80004606 <piperead+0x34>
    80004628:	e85a                	sd	s6,16(sp)
    8000462a:	a809                	j	8000463c <piperead+0x6a>
    8000462c:	e85a                	sd	s6,16(sp)
    8000462e:	a039                	j	8000463c <piperead+0x6a>
      release(&pi->lock);
    80004630:	8526                	mv	a0,s1
    80004632:	e34fc0ef          	jal	80000c66 <release>
      return -1;
    80004636:	59fd                	li	s3,-1
    80004638:	a8b1                	j	80004694 <piperead+0xc2>
    8000463a:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000463c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000463e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004640:	05505263          	blez	s5,80004684 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004644:	2184a783          	lw	a5,536(s1)
    80004648:	21c4a703          	lw	a4,540(s1)
    8000464c:	02f70c63          	beq	a4,a5,80004684 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004650:	0017871b          	addiw	a4,a5,1
    80004654:	20e4ac23          	sw	a4,536(s1)
    80004658:	1ff7f793          	andi	a5,a5,511
    8000465c:	97a6                	add	a5,a5,s1
    8000465e:	0187c783          	lbu	a5,24(a5)
    80004662:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004666:	4685                	li	a3,1
    80004668:	fbf40613          	addi	a2,s0,-65
    8000466c:	85ca                	mv	a1,s2
    8000466e:	068a3503          	ld	a0,104(s4)
    80004672:	f71fc0ef          	jal	800015e2 <copyout>
    80004676:	01650763          	beq	a0,s6,80004684 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000467a:	2985                	addiw	s3,s3,1
    8000467c:	0905                	addi	s2,s2,1
    8000467e:	fd3a93e3          	bne	s5,s3,80004644 <piperead+0x72>
    80004682:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004684:	21c48513          	addi	a0,s1,540
    80004688:	94bfd0ef          	jal	80001fd2 <wakeup>
  release(&pi->lock);
    8000468c:	8526                	mv	a0,s1
    8000468e:	dd8fc0ef          	jal	80000c66 <release>
    80004692:	6b42                	ld	s6,16(sp)
  return i;
}
    80004694:	854e                	mv	a0,s3
    80004696:	60a6                	ld	ra,72(sp)
    80004698:	6406                	ld	s0,64(sp)
    8000469a:	74e2                	ld	s1,56(sp)
    8000469c:	7942                	ld	s2,48(sp)
    8000469e:	79a2                	ld	s3,40(sp)
    800046a0:	7a02                	ld	s4,32(sp)
    800046a2:	6ae2                	ld	s5,24(sp)
    800046a4:	6161                	addi	sp,sp,80
    800046a6:	8082                	ret

00000000800046a8 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    800046a8:	1141                	addi	sp,sp,-16
    800046aa:	e422                	sd	s0,8(sp)
    800046ac:	0800                	addi	s0,sp,16
    800046ae:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800046b0:	8905                	andi	a0,a0,1
    800046b2:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800046b4:	8b89                	andi	a5,a5,2
    800046b6:	c399                	beqz	a5,800046bc <flags2perm+0x14>
      perm |= PTE_W;
    800046b8:	00456513          	ori	a0,a0,4
    return perm;
}
    800046bc:	6422                	ld	s0,8(sp)
    800046be:	0141                	addi	sp,sp,16
    800046c0:	8082                	ret

00000000800046c2 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    800046c2:	df010113          	addi	sp,sp,-528
    800046c6:	20113423          	sd	ra,520(sp)
    800046ca:	20813023          	sd	s0,512(sp)
    800046ce:	ffa6                	sd	s1,504(sp)
    800046d0:	fbca                	sd	s2,496(sp)
    800046d2:	0c00                	addi	s0,sp,528
    800046d4:	892a                	mv	s2,a0
    800046d6:	dea43c23          	sd	a0,-520(s0)
    800046da:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800046de:	9f0fd0ef          	jal	800018ce <myproc>
    800046e2:	84aa                	mv	s1,a0

  begin_op();
    800046e4:	dd4ff0ef          	jal	80003cb8 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800046e8:	854a                	mv	a0,s2
    800046ea:	bfaff0ef          	jal	80003ae4 <namei>
    800046ee:	c931                	beqz	a0,80004742 <kexec+0x80>
    800046f0:	f3d2                	sd	s4,480(sp)
    800046f2:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800046f4:	bdbfe0ef          	jal	800032ce <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800046f8:	04000713          	li	a4,64
    800046fc:	4681                	li	a3,0
    800046fe:	e5040613          	addi	a2,s0,-432
    80004702:	4581                	li	a1,0
    80004704:	8552                	mv	a0,s4
    80004706:	f59fe0ef          	jal	8000365e <readi>
    8000470a:	04000793          	li	a5,64
    8000470e:	00f51a63          	bne	a0,a5,80004722 <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80004712:	e5042703          	lw	a4,-432(s0)
    80004716:	464c47b7          	lui	a5,0x464c4
    8000471a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000471e:	02f70663          	beq	a4,a5,8000474a <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004722:	8552                	mv	a0,s4
    80004724:	db5fe0ef          	jal	800034d8 <iunlockput>
    end_op();
    80004728:	dfaff0ef          	jal	80003d22 <end_op>
  }
  return -1;
    8000472c:	557d                	li	a0,-1
    8000472e:	7a1e                	ld	s4,480(sp)
}
    80004730:	20813083          	ld	ra,520(sp)
    80004734:	20013403          	ld	s0,512(sp)
    80004738:	74fe                	ld	s1,504(sp)
    8000473a:	795e                	ld	s2,496(sp)
    8000473c:	21010113          	addi	sp,sp,528
    80004740:	8082                	ret
    end_op();
    80004742:	de0ff0ef          	jal	80003d22 <end_op>
    return -1;
    80004746:	557d                	li	a0,-1
    80004748:	b7e5                	j	80004730 <kexec+0x6e>
    8000474a:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    8000474c:	8526                	mv	a0,s1
    8000474e:	a86fd0ef          	jal	800019d4 <proc_pagetable>
    80004752:	8b2a                	mv	s6,a0
    80004754:	2c050b63          	beqz	a0,80004a2a <kexec+0x368>
    80004758:	f7ce                	sd	s3,488(sp)
    8000475a:	efd6                	sd	s5,472(sp)
    8000475c:	e7de                	sd	s7,456(sp)
    8000475e:	e3e2                	sd	s8,448(sp)
    80004760:	ff66                	sd	s9,440(sp)
    80004762:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004764:	e7042d03          	lw	s10,-400(s0)
    80004768:	e8845783          	lhu	a5,-376(s0)
    8000476c:	12078963          	beqz	a5,8000489e <kexec+0x1dc>
    80004770:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004772:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004774:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004776:	6c85                	lui	s9,0x1
    80004778:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000477c:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004780:	6a85                	lui	s5,0x1
    80004782:	a085                	j	800047e2 <kexec+0x120>
      panic("loadseg: address should exist");
    80004784:	00003517          	auipc	a0,0x3
    80004788:	e6450513          	addi	a0,a0,-412 # 800075e8 <etext+0x5e8>
    8000478c:	854fc0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    80004790:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004792:	8726                	mv	a4,s1
    80004794:	012c06bb          	addw	a3,s8,s2
    80004798:	4581                	li	a1,0
    8000479a:	8552                	mv	a0,s4
    8000479c:	ec3fe0ef          	jal	8000365e <readi>
    800047a0:	2501                	sext.w	a0,a0
    800047a2:	24a49a63          	bne	s1,a0,800049f6 <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    800047a6:	012a893b          	addw	s2,s5,s2
    800047aa:	03397363          	bgeu	s2,s3,800047d0 <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    800047ae:	02091593          	slli	a1,s2,0x20
    800047b2:	9181                	srli	a1,a1,0x20
    800047b4:	95de                	add	a1,a1,s7
    800047b6:	855a                	mv	a0,s6
    800047b8:	ff8fc0ef          	jal	80000fb0 <walkaddr>
    800047bc:	862a                	mv	a2,a0
    if(pa == 0)
    800047be:	d179                	beqz	a0,80004784 <kexec+0xc2>
    if(sz - i < PGSIZE)
    800047c0:	412984bb          	subw	s1,s3,s2
    800047c4:	0004879b          	sext.w	a5,s1
    800047c8:	fcfcf4e3          	bgeu	s9,a5,80004790 <kexec+0xce>
    800047cc:	84d6                	mv	s1,s5
    800047ce:	b7c9                	j	80004790 <kexec+0xce>
    sz = sz1;
    800047d0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800047d4:	2d85                	addiw	s11,s11,1
    800047d6:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    800047da:	e8845783          	lhu	a5,-376(s0)
    800047de:	08fdd063          	bge	s11,a5,8000485e <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800047e2:	2d01                	sext.w	s10,s10
    800047e4:	03800713          	li	a4,56
    800047e8:	86ea                	mv	a3,s10
    800047ea:	e1840613          	addi	a2,s0,-488
    800047ee:	4581                	li	a1,0
    800047f0:	8552                	mv	a0,s4
    800047f2:	e6dfe0ef          	jal	8000365e <readi>
    800047f6:	03800793          	li	a5,56
    800047fa:	1cf51663          	bne	a0,a5,800049c6 <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    800047fe:	e1842783          	lw	a5,-488(s0)
    80004802:	4705                	li	a4,1
    80004804:	fce798e3          	bne	a5,a4,800047d4 <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004808:	e4043483          	ld	s1,-448(s0)
    8000480c:	e3843783          	ld	a5,-456(s0)
    80004810:	1af4ef63          	bltu	s1,a5,800049ce <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004814:	e2843783          	ld	a5,-472(s0)
    80004818:	94be                	add	s1,s1,a5
    8000481a:	1af4ee63          	bltu	s1,a5,800049d6 <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    8000481e:	df043703          	ld	a4,-528(s0)
    80004822:	8ff9                	and	a5,a5,a4
    80004824:	1a079d63          	bnez	a5,800049de <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004828:	e1c42503          	lw	a0,-484(s0)
    8000482c:	e7dff0ef          	jal	800046a8 <flags2perm>
    80004830:	86aa                	mv	a3,a0
    80004832:	8626                	mv	a2,s1
    80004834:	85ca                	mv	a1,s2
    80004836:	855a                	mv	a0,s6
    80004838:	a51fc0ef          	jal	80001288 <uvmalloc>
    8000483c:	e0a43423          	sd	a0,-504(s0)
    80004840:	1a050363          	beqz	a0,800049e6 <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004844:	e2843b83          	ld	s7,-472(s0)
    80004848:	e2042c03          	lw	s8,-480(s0)
    8000484c:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004850:	00098463          	beqz	s3,80004858 <kexec+0x196>
    80004854:	4901                	li	s2,0
    80004856:	bfa1                	j	800047ae <kexec+0xec>
    sz = sz1;
    80004858:	e0843903          	ld	s2,-504(s0)
    8000485c:	bfa5                	j	800047d4 <kexec+0x112>
    8000485e:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80004860:	8552                	mv	a0,s4
    80004862:	c77fe0ef          	jal	800034d8 <iunlockput>
  end_op();
    80004866:	cbcff0ef          	jal	80003d22 <end_op>
  p = myproc();
    8000486a:	864fd0ef          	jal	800018ce <myproc>
    8000486e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004870:	06053c83          	ld	s9,96(a0)
  sz = PGROUNDUP(sz);
    80004874:	6985                	lui	s3,0x1
    80004876:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004878:	99ca                	add	s3,s3,s2
    8000487a:	77fd                	lui	a5,0xfffff
    8000487c:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004880:	4691                	li	a3,4
    80004882:	6609                	lui	a2,0x2
    80004884:	964e                	add	a2,a2,s3
    80004886:	85ce                	mv	a1,s3
    80004888:	855a                	mv	a0,s6
    8000488a:	9fffc0ef          	jal	80001288 <uvmalloc>
    8000488e:	892a                	mv	s2,a0
    80004890:	e0a43423          	sd	a0,-504(s0)
    80004894:	e519                	bnez	a0,800048a2 <kexec+0x1e0>
  if(pagetable)
    80004896:	e1343423          	sd	s3,-504(s0)
    8000489a:	4a01                	li	s4,0
    8000489c:	aab1                	j	800049f8 <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000489e:	4901                	li	s2,0
    800048a0:	b7c1                	j	80004860 <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800048a2:	75f9                	lui	a1,0xffffe
    800048a4:	95aa                	add	a1,a1,a0
    800048a6:	855a                	mv	a0,s6
    800048a8:	bb7fc0ef          	jal	8000145e <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800048ac:	7bfd                	lui	s7,0xfffff
    800048ae:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800048b0:	e0043783          	ld	a5,-512(s0)
    800048b4:	6388                	ld	a0,0(a5)
    800048b6:	cd39                	beqz	a0,80004914 <kexec+0x252>
    800048b8:	e9040993          	addi	s3,s0,-368
    800048bc:	f9040c13          	addi	s8,s0,-112
    800048c0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800048c2:	d50fc0ef          	jal	80000e12 <strlen>
    800048c6:	0015079b          	addiw	a5,a0,1
    800048ca:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800048ce:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800048d2:	11796e63          	bltu	s2,s7,800049ee <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800048d6:	e0043d03          	ld	s10,-512(s0)
    800048da:	000d3a03          	ld	s4,0(s10)
    800048de:	8552                	mv	a0,s4
    800048e0:	d32fc0ef          	jal	80000e12 <strlen>
    800048e4:	0015069b          	addiw	a3,a0,1
    800048e8:	8652                	mv	a2,s4
    800048ea:	85ca                	mv	a1,s2
    800048ec:	855a                	mv	a0,s6
    800048ee:	cf5fc0ef          	jal	800015e2 <copyout>
    800048f2:	10054063          	bltz	a0,800049f2 <kexec+0x330>
    ustack[argc] = sp;
    800048f6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800048fa:	0485                	addi	s1,s1,1
    800048fc:	008d0793          	addi	a5,s10,8
    80004900:	e0f43023          	sd	a5,-512(s0)
    80004904:	008d3503          	ld	a0,8(s10)
    80004908:	c909                	beqz	a0,8000491a <kexec+0x258>
    if(argc >= MAXARG)
    8000490a:	09a1                	addi	s3,s3,8
    8000490c:	fb899be3          	bne	s3,s8,800048c2 <kexec+0x200>
  ip = 0;
    80004910:	4a01                	li	s4,0
    80004912:	a0dd                	j	800049f8 <kexec+0x336>
  sp = sz;
    80004914:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004918:	4481                	li	s1,0
  ustack[argc] = 0;
    8000491a:	00349793          	slli	a5,s1,0x3
    8000491e:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdddb8>
    80004922:	97a2                	add	a5,a5,s0
    80004924:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004928:	00148693          	addi	a3,s1,1
    8000492c:	068e                	slli	a3,a3,0x3
    8000492e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004932:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004936:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000493a:	f5796ee3          	bltu	s2,s7,80004896 <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000493e:	e9040613          	addi	a2,s0,-368
    80004942:	85ca                	mv	a1,s2
    80004944:	855a                	mv	a0,s6
    80004946:	c9dfc0ef          	jal	800015e2 <copyout>
    8000494a:	0e054263          	bltz	a0,80004a2e <kexec+0x36c>
  p->trapframe->a1 = sp;
    8000494e:	070ab783          	ld	a5,112(s5) # 1070 <_entry-0x7fffef90>
    80004952:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004956:	df843783          	ld	a5,-520(s0)
    8000495a:	0007c703          	lbu	a4,0(a5)
    8000495e:	cf11                	beqz	a4,8000497a <kexec+0x2b8>
    80004960:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004962:	02f00693          	li	a3,47
    80004966:	a039                	j	80004974 <kexec+0x2b2>
      last = s+1;
    80004968:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000496c:	0785                	addi	a5,a5,1
    8000496e:	fff7c703          	lbu	a4,-1(a5)
    80004972:	c701                	beqz	a4,8000497a <kexec+0x2b8>
    if(*s == '/')
    80004974:	fed71ce3          	bne	a4,a3,8000496c <kexec+0x2aa>
    80004978:	bfc5                	j	80004968 <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    8000497a:	4641                	li	a2,16
    8000497c:	df843583          	ld	a1,-520(s0)
    80004980:	170a8513          	addi	a0,s5,368
    80004984:	c5cfc0ef          	jal	80000de0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004988:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    8000498c:	076ab423          	sd	s6,104(s5)
  p->sz = sz;
    80004990:	e0843783          	ld	a5,-504(s0)
    80004994:	06fab023          	sd	a5,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004998:	070ab783          	ld	a5,112(s5)
    8000499c:	e6843703          	ld	a4,-408(s0)
    800049a0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800049a2:	070ab783          	ld	a5,112(s5)
    800049a6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800049aa:	85e6                	mv	a1,s9
    800049ac:	8acfd0ef          	jal	80001a58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800049b0:	0004851b          	sext.w	a0,s1
    800049b4:	79be                	ld	s3,488(sp)
    800049b6:	7a1e                	ld	s4,480(sp)
    800049b8:	6afe                	ld	s5,472(sp)
    800049ba:	6b5e                	ld	s6,464(sp)
    800049bc:	6bbe                	ld	s7,456(sp)
    800049be:	6c1e                	ld	s8,448(sp)
    800049c0:	7cfa                	ld	s9,440(sp)
    800049c2:	7d5a                	ld	s10,432(sp)
    800049c4:	b3b5                	j	80004730 <kexec+0x6e>
    800049c6:	e1243423          	sd	s2,-504(s0)
    800049ca:	7dba                	ld	s11,424(sp)
    800049cc:	a035                	j	800049f8 <kexec+0x336>
    800049ce:	e1243423          	sd	s2,-504(s0)
    800049d2:	7dba                	ld	s11,424(sp)
    800049d4:	a015                	j	800049f8 <kexec+0x336>
    800049d6:	e1243423          	sd	s2,-504(s0)
    800049da:	7dba                	ld	s11,424(sp)
    800049dc:	a831                	j	800049f8 <kexec+0x336>
    800049de:	e1243423          	sd	s2,-504(s0)
    800049e2:	7dba                	ld	s11,424(sp)
    800049e4:	a811                	j	800049f8 <kexec+0x336>
    800049e6:	e1243423          	sd	s2,-504(s0)
    800049ea:	7dba                	ld	s11,424(sp)
    800049ec:	a031                	j	800049f8 <kexec+0x336>
  ip = 0;
    800049ee:	4a01                	li	s4,0
    800049f0:	a021                	j	800049f8 <kexec+0x336>
    800049f2:	4a01                	li	s4,0
  if(pagetable)
    800049f4:	a011                	j	800049f8 <kexec+0x336>
    800049f6:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    800049f8:	e0843583          	ld	a1,-504(s0)
    800049fc:	855a                	mv	a0,s6
    800049fe:	85afd0ef          	jal	80001a58 <proc_freepagetable>
  return -1;
    80004a02:	557d                	li	a0,-1
  if(ip){
    80004a04:	000a1b63          	bnez	s4,80004a1a <kexec+0x358>
    80004a08:	79be                	ld	s3,488(sp)
    80004a0a:	7a1e                	ld	s4,480(sp)
    80004a0c:	6afe                	ld	s5,472(sp)
    80004a0e:	6b5e                	ld	s6,464(sp)
    80004a10:	6bbe                	ld	s7,456(sp)
    80004a12:	6c1e                	ld	s8,448(sp)
    80004a14:	7cfa                	ld	s9,440(sp)
    80004a16:	7d5a                	ld	s10,432(sp)
    80004a18:	bb21                	j	80004730 <kexec+0x6e>
    80004a1a:	79be                	ld	s3,488(sp)
    80004a1c:	6afe                	ld	s5,472(sp)
    80004a1e:	6b5e                	ld	s6,464(sp)
    80004a20:	6bbe                	ld	s7,456(sp)
    80004a22:	6c1e                	ld	s8,448(sp)
    80004a24:	7cfa                	ld	s9,440(sp)
    80004a26:	7d5a                	ld	s10,432(sp)
    80004a28:	b9ed                	j	80004722 <kexec+0x60>
    80004a2a:	6b5e                	ld	s6,464(sp)
    80004a2c:	b9dd                	j	80004722 <kexec+0x60>
  sz = sz1;
    80004a2e:	e0843983          	ld	s3,-504(s0)
    80004a32:	b595                	j	80004896 <kexec+0x1d4>

0000000080004a34 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004a34:	7179                	addi	sp,sp,-48
    80004a36:	f406                	sd	ra,40(sp)
    80004a38:	f022                	sd	s0,32(sp)
    80004a3a:	ec26                	sd	s1,24(sp)
    80004a3c:	e84a                	sd	s2,16(sp)
    80004a3e:	1800                	addi	s0,sp,48
    80004a40:	892e                	mv	s2,a1
    80004a42:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004a44:	fdc40593          	addi	a1,s0,-36
    80004a48:	e65fd0ef          	jal	800028ac <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004a4c:	fdc42703          	lw	a4,-36(s0)
    80004a50:	47bd                	li	a5,15
    80004a52:	02e7e963          	bltu	a5,a4,80004a84 <argfd+0x50>
    80004a56:	e79fc0ef          	jal	800018ce <myproc>
    80004a5a:	fdc42703          	lw	a4,-36(s0)
    80004a5e:	01c70793          	addi	a5,a4,28
    80004a62:	078e                	slli	a5,a5,0x3
    80004a64:	953e                	add	a0,a0,a5
    80004a66:	651c                	ld	a5,8(a0)
    80004a68:	c385                	beqz	a5,80004a88 <argfd+0x54>
    return -1;
  if(pfd)
    80004a6a:	00090463          	beqz	s2,80004a72 <argfd+0x3e>
    *pfd = fd;
    80004a6e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004a72:	4501                	li	a0,0
  if(pf)
    80004a74:	c091                	beqz	s1,80004a78 <argfd+0x44>
    *pf = f;
    80004a76:	e09c                	sd	a5,0(s1)
}
    80004a78:	70a2                	ld	ra,40(sp)
    80004a7a:	7402                	ld	s0,32(sp)
    80004a7c:	64e2                	ld	s1,24(sp)
    80004a7e:	6942                	ld	s2,16(sp)
    80004a80:	6145                	addi	sp,sp,48
    80004a82:	8082                	ret
    return -1;
    80004a84:	557d                	li	a0,-1
    80004a86:	bfcd                	j	80004a78 <argfd+0x44>
    80004a88:	557d                	li	a0,-1
    80004a8a:	b7fd                	j	80004a78 <argfd+0x44>

0000000080004a8c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004a8c:	1101                	addi	sp,sp,-32
    80004a8e:	ec06                	sd	ra,24(sp)
    80004a90:	e822                	sd	s0,16(sp)
    80004a92:	e426                	sd	s1,8(sp)
    80004a94:	1000                	addi	s0,sp,32
    80004a96:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004a98:	e37fc0ef          	jal	800018ce <myproc>
    80004a9c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004a9e:	0e850793          	addi	a5,a0,232
    80004aa2:	4501                	li	a0,0
    80004aa4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004aa6:	6398                	ld	a4,0(a5)
    80004aa8:	cb19                	beqz	a4,80004abe <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004aaa:	2505                	addiw	a0,a0,1
    80004aac:	07a1                	addi	a5,a5,8
    80004aae:	fed51ce3          	bne	a0,a3,80004aa6 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004ab2:	557d                	li	a0,-1
}
    80004ab4:	60e2                	ld	ra,24(sp)
    80004ab6:	6442                	ld	s0,16(sp)
    80004ab8:	64a2                	ld	s1,8(sp)
    80004aba:	6105                	addi	sp,sp,32
    80004abc:	8082                	ret
      p->ofile[fd] = f;
    80004abe:	01c50793          	addi	a5,a0,28
    80004ac2:	078e                	slli	a5,a5,0x3
    80004ac4:	963e                	add	a2,a2,a5
    80004ac6:	e604                	sd	s1,8(a2)
      return fd;
    80004ac8:	b7f5                	j	80004ab4 <fdalloc+0x28>

0000000080004aca <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004aca:	715d                	addi	sp,sp,-80
    80004acc:	e486                	sd	ra,72(sp)
    80004ace:	e0a2                	sd	s0,64(sp)
    80004ad0:	fc26                	sd	s1,56(sp)
    80004ad2:	f84a                	sd	s2,48(sp)
    80004ad4:	f44e                	sd	s3,40(sp)
    80004ad6:	ec56                	sd	s5,24(sp)
    80004ad8:	e85a                	sd	s6,16(sp)
    80004ada:	0880                	addi	s0,sp,80
    80004adc:	8b2e                	mv	s6,a1
    80004ade:	89b2                	mv	s3,a2
    80004ae0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004ae2:	fb040593          	addi	a1,s0,-80
    80004ae6:	818ff0ef          	jal	80003afe <nameiparent>
    80004aea:	84aa                	mv	s1,a0
    80004aec:	10050a63          	beqz	a0,80004c00 <create+0x136>
    return 0;

  ilock(dp);
    80004af0:	fdefe0ef          	jal	800032ce <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004af4:	4601                	li	a2,0
    80004af6:	fb040593          	addi	a1,s0,-80
    80004afa:	8526                	mv	a0,s1
    80004afc:	d83fe0ef          	jal	8000387e <dirlookup>
    80004b00:	8aaa                	mv	s5,a0
    80004b02:	c129                	beqz	a0,80004b44 <create+0x7a>
    iunlockput(dp);
    80004b04:	8526                	mv	a0,s1
    80004b06:	9d3fe0ef          	jal	800034d8 <iunlockput>
    ilock(ip);
    80004b0a:	8556                	mv	a0,s5
    80004b0c:	fc2fe0ef          	jal	800032ce <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004b10:	4789                	li	a5,2
    80004b12:	02fb1463          	bne	s6,a5,80004b3a <create+0x70>
    80004b16:	044ad783          	lhu	a5,68(s5)
    80004b1a:	37f9                	addiw	a5,a5,-2
    80004b1c:	17c2                	slli	a5,a5,0x30
    80004b1e:	93c1                	srli	a5,a5,0x30
    80004b20:	4705                	li	a4,1
    80004b22:	00f76c63          	bltu	a4,a5,80004b3a <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004b26:	8556                	mv	a0,s5
    80004b28:	60a6                	ld	ra,72(sp)
    80004b2a:	6406                	ld	s0,64(sp)
    80004b2c:	74e2                	ld	s1,56(sp)
    80004b2e:	7942                	ld	s2,48(sp)
    80004b30:	79a2                	ld	s3,40(sp)
    80004b32:	6ae2                	ld	s5,24(sp)
    80004b34:	6b42                	ld	s6,16(sp)
    80004b36:	6161                	addi	sp,sp,80
    80004b38:	8082                	ret
    iunlockput(ip);
    80004b3a:	8556                	mv	a0,s5
    80004b3c:	99dfe0ef          	jal	800034d8 <iunlockput>
    return 0;
    80004b40:	4a81                	li	s5,0
    80004b42:	b7d5                	j	80004b26 <create+0x5c>
    80004b44:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004b46:	85da                	mv	a1,s6
    80004b48:	4088                	lw	a0,0(s1)
    80004b4a:	e14fe0ef          	jal	8000315e <ialloc>
    80004b4e:	8a2a                	mv	s4,a0
    80004b50:	cd15                	beqz	a0,80004b8c <create+0xc2>
  ilock(ip);
    80004b52:	f7cfe0ef          	jal	800032ce <ilock>
  ip->major = major;
    80004b56:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004b5a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004b5e:	4905                	li	s2,1
    80004b60:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004b64:	8552                	mv	a0,s4
    80004b66:	eb4fe0ef          	jal	8000321a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004b6a:	032b0763          	beq	s6,s2,80004b98 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004b6e:	004a2603          	lw	a2,4(s4)
    80004b72:	fb040593          	addi	a1,s0,-80
    80004b76:	8526                	mv	a0,s1
    80004b78:	ed3fe0ef          	jal	80003a4a <dirlink>
    80004b7c:	06054563          	bltz	a0,80004be6 <create+0x11c>
  iunlockput(dp);
    80004b80:	8526                	mv	a0,s1
    80004b82:	957fe0ef          	jal	800034d8 <iunlockput>
  return ip;
    80004b86:	8ad2                	mv	s5,s4
    80004b88:	7a02                	ld	s4,32(sp)
    80004b8a:	bf71                	j	80004b26 <create+0x5c>
    iunlockput(dp);
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	94bfe0ef          	jal	800034d8 <iunlockput>
    return 0;
    80004b92:	8ad2                	mv	s5,s4
    80004b94:	7a02                	ld	s4,32(sp)
    80004b96:	bf41                	j	80004b26 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004b98:	004a2603          	lw	a2,4(s4)
    80004b9c:	00003597          	auipc	a1,0x3
    80004ba0:	a6c58593          	addi	a1,a1,-1428 # 80007608 <etext+0x608>
    80004ba4:	8552                	mv	a0,s4
    80004ba6:	ea5fe0ef          	jal	80003a4a <dirlink>
    80004baa:	02054e63          	bltz	a0,80004be6 <create+0x11c>
    80004bae:	40d0                	lw	a2,4(s1)
    80004bb0:	00003597          	auipc	a1,0x3
    80004bb4:	a6058593          	addi	a1,a1,-1440 # 80007610 <etext+0x610>
    80004bb8:	8552                	mv	a0,s4
    80004bba:	e91fe0ef          	jal	80003a4a <dirlink>
    80004bbe:	02054463          	bltz	a0,80004be6 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004bc2:	004a2603          	lw	a2,4(s4)
    80004bc6:	fb040593          	addi	a1,s0,-80
    80004bca:	8526                	mv	a0,s1
    80004bcc:	e7ffe0ef          	jal	80003a4a <dirlink>
    80004bd0:	00054b63          	bltz	a0,80004be6 <create+0x11c>
    dp->nlink++;  // for ".."
    80004bd4:	04a4d783          	lhu	a5,74(s1)
    80004bd8:	2785                	addiw	a5,a5,1
    80004bda:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004bde:	8526                	mv	a0,s1
    80004be0:	e3afe0ef          	jal	8000321a <iupdate>
    80004be4:	bf71                	j	80004b80 <create+0xb6>
  ip->nlink = 0;
    80004be6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004bea:	8552                	mv	a0,s4
    80004bec:	e2efe0ef          	jal	8000321a <iupdate>
  iunlockput(ip);
    80004bf0:	8552                	mv	a0,s4
    80004bf2:	8e7fe0ef          	jal	800034d8 <iunlockput>
  iunlockput(dp);
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	8e1fe0ef          	jal	800034d8 <iunlockput>
  return 0;
    80004bfc:	7a02                	ld	s4,32(sp)
    80004bfe:	b725                	j	80004b26 <create+0x5c>
    return 0;
    80004c00:	8aaa                	mv	s5,a0
    80004c02:	b715                	j	80004b26 <create+0x5c>

0000000080004c04 <sys_dup>:
{
    80004c04:	7179                	addi	sp,sp,-48
    80004c06:	f406                	sd	ra,40(sp)
    80004c08:	f022                	sd	s0,32(sp)
    80004c0a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004c0c:	fd840613          	addi	a2,s0,-40
    80004c10:	4581                	li	a1,0
    80004c12:	4501                	li	a0,0
    80004c14:	e21ff0ef          	jal	80004a34 <argfd>
    return -1;
    80004c18:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004c1a:	02054363          	bltz	a0,80004c40 <sys_dup+0x3c>
    80004c1e:	ec26                	sd	s1,24(sp)
    80004c20:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004c22:	fd843903          	ld	s2,-40(s0)
    80004c26:	854a                	mv	a0,s2
    80004c28:	e65ff0ef          	jal	80004a8c <fdalloc>
    80004c2c:	84aa                	mv	s1,a0
    return -1;
    80004c2e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004c30:	00054d63          	bltz	a0,80004c4a <sys_dup+0x46>
  filedup(f);
    80004c34:	854a                	mv	a0,s2
    80004c36:	c48ff0ef          	jal	8000407e <filedup>
  return fd;
    80004c3a:	87a6                	mv	a5,s1
    80004c3c:	64e2                	ld	s1,24(sp)
    80004c3e:	6942                	ld	s2,16(sp)
}
    80004c40:	853e                	mv	a0,a5
    80004c42:	70a2                	ld	ra,40(sp)
    80004c44:	7402                	ld	s0,32(sp)
    80004c46:	6145                	addi	sp,sp,48
    80004c48:	8082                	ret
    80004c4a:	64e2                	ld	s1,24(sp)
    80004c4c:	6942                	ld	s2,16(sp)
    80004c4e:	bfcd                	j	80004c40 <sys_dup+0x3c>

0000000080004c50 <sys_read>:
{
    80004c50:	7179                	addi	sp,sp,-48
    80004c52:	f406                	sd	ra,40(sp)
    80004c54:	f022                	sd	s0,32(sp)
    80004c56:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004c58:	fd840593          	addi	a1,s0,-40
    80004c5c:	4505                	li	a0,1
    80004c5e:	c6bfd0ef          	jal	800028c8 <argaddr>
  argint(2, &n);
    80004c62:	fe440593          	addi	a1,s0,-28
    80004c66:	4509                	li	a0,2
    80004c68:	c45fd0ef          	jal	800028ac <argint>
  if(argfd(0, 0, &f) < 0)
    80004c6c:	fe840613          	addi	a2,s0,-24
    80004c70:	4581                	li	a1,0
    80004c72:	4501                	li	a0,0
    80004c74:	dc1ff0ef          	jal	80004a34 <argfd>
    80004c78:	87aa                	mv	a5,a0
    return -1;
    80004c7a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004c7c:	0007ca63          	bltz	a5,80004c90 <sys_read+0x40>
  return fileread(f, p, n);
    80004c80:	fe442603          	lw	a2,-28(s0)
    80004c84:	fd843583          	ld	a1,-40(s0)
    80004c88:	fe843503          	ld	a0,-24(s0)
    80004c8c:	d58ff0ef          	jal	800041e4 <fileread>
}
    80004c90:	70a2                	ld	ra,40(sp)
    80004c92:	7402                	ld	s0,32(sp)
    80004c94:	6145                	addi	sp,sp,48
    80004c96:	8082                	ret

0000000080004c98 <sys_write>:
{
    80004c98:	7179                	addi	sp,sp,-48
    80004c9a:	f406                	sd	ra,40(sp)
    80004c9c:	f022                	sd	s0,32(sp)
    80004c9e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004ca0:	fd840593          	addi	a1,s0,-40
    80004ca4:	4505                	li	a0,1
    80004ca6:	c23fd0ef          	jal	800028c8 <argaddr>
  argint(2, &n);
    80004caa:	fe440593          	addi	a1,s0,-28
    80004cae:	4509                	li	a0,2
    80004cb0:	bfdfd0ef          	jal	800028ac <argint>
  if(argfd(0, 0, &f) < 0)
    80004cb4:	fe840613          	addi	a2,s0,-24
    80004cb8:	4581                	li	a1,0
    80004cba:	4501                	li	a0,0
    80004cbc:	d79ff0ef          	jal	80004a34 <argfd>
    80004cc0:	87aa                	mv	a5,a0
    return -1;
    80004cc2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004cc4:	0007ca63          	bltz	a5,80004cd8 <sys_write+0x40>
  return filewrite(f, p, n);
    80004cc8:	fe442603          	lw	a2,-28(s0)
    80004ccc:	fd843583          	ld	a1,-40(s0)
    80004cd0:	fe843503          	ld	a0,-24(s0)
    80004cd4:	dceff0ef          	jal	800042a2 <filewrite>
}
    80004cd8:	70a2                	ld	ra,40(sp)
    80004cda:	7402                	ld	s0,32(sp)
    80004cdc:	6145                	addi	sp,sp,48
    80004cde:	8082                	ret

0000000080004ce0 <sys_close>:
{
    80004ce0:	1101                	addi	sp,sp,-32
    80004ce2:	ec06                	sd	ra,24(sp)
    80004ce4:	e822                	sd	s0,16(sp)
    80004ce6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004ce8:	fe040613          	addi	a2,s0,-32
    80004cec:	fec40593          	addi	a1,s0,-20
    80004cf0:	4501                	li	a0,0
    80004cf2:	d43ff0ef          	jal	80004a34 <argfd>
    return -1;
    80004cf6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004cf8:	02054063          	bltz	a0,80004d18 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004cfc:	bd3fc0ef          	jal	800018ce <myproc>
    80004d00:	fec42783          	lw	a5,-20(s0)
    80004d04:	07f1                	addi	a5,a5,28
    80004d06:	078e                	slli	a5,a5,0x3
    80004d08:	953e                	add	a0,a0,a5
    80004d0a:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80004d0e:	fe043503          	ld	a0,-32(s0)
    80004d12:	bb2ff0ef          	jal	800040c4 <fileclose>
  return 0;
    80004d16:	4781                	li	a5,0
}
    80004d18:	853e                	mv	a0,a5
    80004d1a:	60e2                	ld	ra,24(sp)
    80004d1c:	6442                	ld	s0,16(sp)
    80004d1e:	6105                	addi	sp,sp,32
    80004d20:	8082                	ret

0000000080004d22 <sys_fstat>:
{
    80004d22:	1101                	addi	sp,sp,-32
    80004d24:	ec06                	sd	ra,24(sp)
    80004d26:	e822                	sd	s0,16(sp)
    80004d28:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004d2a:	fe040593          	addi	a1,s0,-32
    80004d2e:	4505                	li	a0,1
    80004d30:	b99fd0ef          	jal	800028c8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004d34:	fe840613          	addi	a2,s0,-24
    80004d38:	4581                	li	a1,0
    80004d3a:	4501                	li	a0,0
    80004d3c:	cf9ff0ef          	jal	80004a34 <argfd>
    80004d40:	87aa                	mv	a5,a0
    return -1;
    80004d42:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d44:	0007c863          	bltz	a5,80004d54 <sys_fstat+0x32>
  return filestat(f, st);
    80004d48:	fe043583          	ld	a1,-32(s0)
    80004d4c:	fe843503          	ld	a0,-24(s0)
    80004d50:	c36ff0ef          	jal	80004186 <filestat>
}
    80004d54:	60e2                	ld	ra,24(sp)
    80004d56:	6442                	ld	s0,16(sp)
    80004d58:	6105                	addi	sp,sp,32
    80004d5a:	8082                	ret

0000000080004d5c <sys_link>:
{
    80004d5c:	7169                	addi	sp,sp,-304
    80004d5e:	f606                	sd	ra,296(sp)
    80004d60:	f222                	sd	s0,288(sp)
    80004d62:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d64:	08000613          	li	a2,128
    80004d68:	ed040593          	addi	a1,s0,-304
    80004d6c:	4501                	li	a0,0
    80004d6e:	b77fd0ef          	jal	800028e4 <argstr>
    return -1;
    80004d72:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d74:	0c054e63          	bltz	a0,80004e50 <sys_link+0xf4>
    80004d78:	08000613          	li	a2,128
    80004d7c:	f5040593          	addi	a1,s0,-176
    80004d80:	4505                	li	a0,1
    80004d82:	b63fd0ef          	jal	800028e4 <argstr>
    return -1;
    80004d86:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d88:	0c054463          	bltz	a0,80004e50 <sys_link+0xf4>
    80004d8c:	ee26                	sd	s1,280(sp)
  begin_op();
    80004d8e:	f2bfe0ef          	jal	80003cb8 <begin_op>
  if((ip = namei(old)) == 0){
    80004d92:	ed040513          	addi	a0,s0,-304
    80004d96:	d4ffe0ef          	jal	80003ae4 <namei>
    80004d9a:	84aa                	mv	s1,a0
    80004d9c:	c53d                	beqz	a0,80004e0a <sys_link+0xae>
  ilock(ip);
    80004d9e:	d30fe0ef          	jal	800032ce <ilock>
  if(ip->type == T_DIR){
    80004da2:	04449703          	lh	a4,68(s1)
    80004da6:	4785                	li	a5,1
    80004da8:	06f70663          	beq	a4,a5,80004e14 <sys_link+0xb8>
    80004dac:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80004dae:	04a4d783          	lhu	a5,74(s1)
    80004db2:	2785                	addiw	a5,a5,1
    80004db4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004db8:	8526                	mv	a0,s1
    80004dba:	c60fe0ef          	jal	8000321a <iupdate>
  iunlock(ip);
    80004dbe:	8526                	mv	a0,s1
    80004dc0:	dbcfe0ef          	jal	8000337c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004dc4:	fd040593          	addi	a1,s0,-48
    80004dc8:	f5040513          	addi	a0,s0,-176
    80004dcc:	d33fe0ef          	jal	80003afe <nameiparent>
    80004dd0:	892a                	mv	s2,a0
    80004dd2:	cd21                	beqz	a0,80004e2a <sys_link+0xce>
  ilock(dp);
    80004dd4:	cfafe0ef          	jal	800032ce <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004dd8:	00092703          	lw	a4,0(s2)
    80004ddc:	409c                	lw	a5,0(s1)
    80004dde:	04f71363          	bne	a4,a5,80004e24 <sys_link+0xc8>
    80004de2:	40d0                	lw	a2,4(s1)
    80004de4:	fd040593          	addi	a1,s0,-48
    80004de8:	854a                	mv	a0,s2
    80004dea:	c61fe0ef          	jal	80003a4a <dirlink>
    80004dee:	02054b63          	bltz	a0,80004e24 <sys_link+0xc8>
  iunlockput(dp);
    80004df2:	854a                	mv	a0,s2
    80004df4:	ee4fe0ef          	jal	800034d8 <iunlockput>
  iput(ip);
    80004df8:	8526                	mv	a0,s1
    80004dfa:	e56fe0ef          	jal	80003450 <iput>
  end_op();
    80004dfe:	f25fe0ef          	jal	80003d22 <end_op>
  return 0;
    80004e02:	4781                	li	a5,0
    80004e04:	64f2                	ld	s1,280(sp)
    80004e06:	6952                	ld	s2,272(sp)
    80004e08:	a0a1                	j	80004e50 <sys_link+0xf4>
    end_op();
    80004e0a:	f19fe0ef          	jal	80003d22 <end_op>
    return -1;
    80004e0e:	57fd                	li	a5,-1
    80004e10:	64f2                	ld	s1,280(sp)
    80004e12:	a83d                	j	80004e50 <sys_link+0xf4>
    iunlockput(ip);
    80004e14:	8526                	mv	a0,s1
    80004e16:	ec2fe0ef          	jal	800034d8 <iunlockput>
    end_op();
    80004e1a:	f09fe0ef          	jal	80003d22 <end_op>
    return -1;
    80004e1e:	57fd                	li	a5,-1
    80004e20:	64f2                	ld	s1,280(sp)
    80004e22:	a03d                	j	80004e50 <sys_link+0xf4>
    iunlockput(dp);
    80004e24:	854a                	mv	a0,s2
    80004e26:	eb2fe0ef          	jal	800034d8 <iunlockput>
  ilock(ip);
    80004e2a:	8526                	mv	a0,s1
    80004e2c:	ca2fe0ef          	jal	800032ce <ilock>
  ip->nlink--;
    80004e30:	04a4d783          	lhu	a5,74(s1)
    80004e34:	37fd                	addiw	a5,a5,-1
    80004e36:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	bdefe0ef          	jal	8000321a <iupdate>
  iunlockput(ip);
    80004e40:	8526                	mv	a0,s1
    80004e42:	e96fe0ef          	jal	800034d8 <iunlockput>
  end_op();
    80004e46:	eddfe0ef          	jal	80003d22 <end_op>
  return -1;
    80004e4a:	57fd                	li	a5,-1
    80004e4c:	64f2                	ld	s1,280(sp)
    80004e4e:	6952                	ld	s2,272(sp)
}
    80004e50:	853e                	mv	a0,a5
    80004e52:	70b2                	ld	ra,296(sp)
    80004e54:	7412                	ld	s0,288(sp)
    80004e56:	6155                	addi	sp,sp,304
    80004e58:	8082                	ret

0000000080004e5a <sys_unlink>:
{
    80004e5a:	7151                	addi	sp,sp,-240
    80004e5c:	f586                	sd	ra,232(sp)
    80004e5e:	f1a2                	sd	s0,224(sp)
    80004e60:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004e62:	08000613          	li	a2,128
    80004e66:	f3040593          	addi	a1,s0,-208
    80004e6a:	4501                	li	a0,0
    80004e6c:	a79fd0ef          	jal	800028e4 <argstr>
    80004e70:	16054063          	bltz	a0,80004fd0 <sys_unlink+0x176>
    80004e74:	eda6                	sd	s1,216(sp)
  begin_op();
    80004e76:	e43fe0ef          	jal	80003cb8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004e7a:	fb040593          	addi	a1,s0,-80
    80004e7e:	f3040513          	addi	a0,s0,-208
    80004e82:	c7dfe0ef          	jal	80003afe <nameiparent>
    80004e86:	84aa                	mv	s1,a0
    80004e88:	c945                	beqz	a0,80004f38 <sys_unlink+0xde>
  ilock(dp);
    80004e8a:	c44fe0ef          	jal	800032ce <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004e8e:	00002597          	auipc	a1,0x2
    80004e92:	77a58593          	addi	a1,a1,1914 # 80007608 <etext+0x608>
    80004e96:	fb040513          	addi	a0,s0,-80
    80004e9a:	9cffe0ef          	jal	80003868 <namecmp>
    80004e9e:	10050e63          	beqz	a0,80004fba <sys_unlink+0x160>
    80004ea2:	00002597          	auipc	a1,0x2
    80004ea6:	76e58593          	addi	a1,a1,1902 # 80007610 <etext+0x610>
    80004eaa:	fb040513          	addi	a0,s0,-80
    80004eae:	9bbfe0ef          	jal	80003868 <namecmp>
    80004eb2:	10050463          	beqz	a0,80004fba <sys_unlink+0x160>
    80004eb6:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004eb8:	f2c40613          	addi	a2,s0,-212
    80004ebc:	fb040593          	addi	a1,s0,-80
    80004ec0:	8526                	mv	a0,s1
    80004ec2:	9bdfe0ef          	jal	8000387e <dirlookup>
    80004ec6:	892a                	mv	s2,a0
    80004ec8:	0e050863          	beqz	a0,80004fb8 <sys_unlink+0x15e>
  ilock(ip);
    80004ecc:	c02fe0ef          	jal	800032ce <ilock>
  if(ip->nlink < 1)
    80004ed0:	04a91783          	lh	a5,74(s2)
    80004ed4:	06f05763          	blez	a5,80004f42 <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004ed8:	04491703          	lh	a4,68(s2)
    80004edc:	4785                	li	a5,1
    80004ede:	06f70963          	beq	a4,a5,80004f50 <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    80004ee2:	4641                	li	a2,16
    80004ee4:	4581                	li	a1,0
    80004ee6:	fc040513          	addi	a0,s0,-64
    80004eea:	db9fb0ef          	jal	80000ca2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004eee:	4741                	li	a4,16
    80004ef0:	f2c42683          	lw	a3,-212(s0)
    80004ef4:	fc040613          	addi	a2,s0,-64
    80004ef8:	4581                	li	a1,0
    80004efa:	8526                	mv	a0,s1
    80004efc:	85ffe0ef          	jal	8000375a <writei>
    80004f00:	47c1                	li	a5,16
    80004f02:	08f51b63          	bne	a0,a5,80004f98 <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    80004f06:	04491703          	lh	a4,68(s2)
    80004f0a:	4785                	li	a5,1
    80004f0c:	08f70d63          	beq	a4,a5,80004fa6 <sys_unlink+0x14c>
  iunlockput(dp);
    80004f10:	8526                	mv	a0,s1
    80004f12:	dc6fe0ef          	jal	800034d8 <iunlockput>
  ip->nlink--;
    80004f16:	04a95783          	lhu	a5,74(s2)
    80004f1a:	37fd                	addiw	a5,a5,-1
    80004f1c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004f20:	854a                	mv	a0,s2
    80004f22:	af8fe0ef          	jal	8000321a <iupdate>
  iunlockput(ip);
    80004f26:	854a                	mv	a0,s2
    80004f28:	db0fe0ef          	jal	800034d8 <iunlockput>
  end_op();
    80004f2c:	df7fe0ef          	jal	80003d22 <end_op>
  return 0;
    80004f30:	4501                	li	a0,0
    80004f32:	64ee                	ld	s1,216(sp)
    80004f34:	694e                	ld	s2,208(sp)
    80004f36:	a849                	j	80004fc8 <sys_unlink+0x16e>
    end_op();
    80004f38:	debfe0ef          	jal	80003d22 <end_op>
    return -1;
    80004f3c:	557d                	li	a0,-1
    80004f3e:	64ee                	ld	s1,216(sp)
    80004f40:	a061                	j	80004fc8 <sys_unlink+0x16e>
    80004f42:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80004f44:	00002517          	auipc	a0,0x2
    80004f48:	6d450513          	addi	a0,a0,1748 # 80007618 <etext+0x618>
    80004f4c:	895fb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004f50:	04c92703          	lw	a4,76(s2)
    80004f54:	02000793          	li	a5,32
    80004f58:	f8e7f5e3          	bgeu	a5,a4,80004ee2 <sys_unlink+0x88>
    80004f5c:	e5ce                	sd	s3,200(sp)
    80004f5e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004f62:	4741                	li	a4,16
    80004f64:	86ce                	mv	a3,s3
    80004f66:	f1840613          	addi	a2,s0,-232
    80004f6a:	4581                	li	a1,0
    80004f6c:	854a                	mv	a0,s2
    80004f6e:	ef0fe0ef          	jal	8000365e <readi>
    80004f72:	47c1                	li	a5,16
    80004f74:	00f51c63          	bne	a0,a5,80004f8c <sys_unlink+0x132>
    if(de.inum != 0)
    80004f78:	f1845783          	lhu	a5,-232(s0)
    80004f7c:	efa1                	bnez	a5,80004fd4 <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004f7e:	29c1                	addiw	s3,s3,16
    80004f80:	04c92783          	lw	a5,76(s2)
    80004f84:	fcf9efe3          	bltu	s3,a5,80004f62 <sys_unlink+0x108>
    80004f88:	69ae                	ld	s3,200(sp)
    80004f8a:	bfa1                	j	80004ee2 <sys_unlink+0x88>
      panic("isdirempty: readi");
    80004f8c:	00002517          	auipc	a0,0x2
    80004f90:	6a450513          	addi	a0,a0,1700 # 80007630 <etext+0x630>
    80004f94:	84dfb0ef          	jal	800007e0 <panic>
    80004f98:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80004f9a:	00002517          	auipc	a0,0x2
    80004f9e:	6ae50513          	addi	a0,a0,1710 # 80007648 <etext+0x648>
    80004fa2:	83ffb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    80004fa6:	04a4d783          	lhu	a5,74(s1)
    80004faa:	37fd                	addiw	a5,a5,-1
    80004fac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004fb0:	8526                	mv	a0,s1
    80004fb2:	a68fe0ef          	jal	8000321a <iupdate>
    80004fb6:	bfa9                	j	80004f10 <sys_unlink+0xb6>
    80004fb8:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80004fba:	8526                	mv	a0,s1
    80004fbc:	d1cfe0ef          	jal	800034d8 <iunlockput>
  end_op();
    80004fc0:	d63fe0ef          	jal	80003d22 <end_op>
  return -1;
    80004fc4:	557d                	li	a0,-1
    80004fc6:	64ee                	ld	s1,216(sp)
}
    80004fc8:	70ae                	ld	ra,232(sp)
    80004fca:	740e                	ld	s0,224(sp)
    80004fcc:	616d                	addi	sp,sp,240
    80004fce:	8082                	ret
    return -1;
    80004fd0:	557d                	li	a0,-1
    80004fd2:	bfdd                	j	80004fc8 <sys_unlink+0x16e>
    iunlockput(ip);
    80004fd4:	854a                	mv	a0,s2
    80004fd6:	d02fe0ef          	jal	800034d8 <iunlockput>
    goto bad;
    80004fda:	694e                	ld	s2,208(sp)
    80004fdc:	69ae                	ld	s3,200(sp)
    80004fde:	bff1                	j	80004fba <sys_unlink+0x160>

0000000080004fe0 <sys_open>:

uint64
sys_open(void)
{
    80004fe0:	7131                	addi	sp,sp,-192
    80004fe2:	fd06                	sd	ra,184(sp)
    80004fe4:	f922                	sd	s0,176(sp)
    80004fe6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80004fe8:	f4c40593          	addi	a1,s0,-180
    80004fec:	4505                	li	a0,1
    80004fee:	8bffd0ef          	jal	800028ac <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004ff2:	08000613          	li	a2,128
    80004ff6:	f5040593          	addi	a1,s0,-176
    80004ffa:	4501                	li	a0,0
    80004ffc:	8e9fd0ef          	jal	800028e4 <argstr>
    80005000:	87aa                	mv	a5,a0
    return -1;
    80005002:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005004:	0a07c263          	bltz	a5,800050a8 <sys_open+0xc8>
    80005008:	f526                	sd	s1,168(sp)

  begin_op();
    8000500a:	caffe0ef          	jal	80003cb8 <begin_op>

  if(omode & O_CREATE){
    8000500e:	f4c42783          	lw	a5,-180(s0)
    80005012:	2007f793          	andi	a5,a5,512
    80005016:	c3d5                	beqz	a5,800050ba <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80005018:	4681                	li	a3,0
    8000501a:	4601                	li	a2,0
    8000501c:	4589                	li	a1,2
    8000501e:	f5040513          	addi	a0,s0,-176
    80005022:	aa9ff0ef          	jal	80004aca <create>
    80005026:	84aa                	mv	s1,a0
    if(ip == 0){
    80005028:	c541                	beqz	a0,800050b0 <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000502a:	04449703          	lh	a4,68(s1)
    8000502e:	478d                	li	a5,3
    80005030:	00f71763          	bne	a4,a5,8000503e <sys_open+0x5e>
    80005034:	0464d703          	lhu	a4,70(s1)
    80005038:	47a5                	li	a5,9
    8000503a:	0ae7ed63          	bltu	a5,a4,800050f4 <sys_open+0x114>
    8000503e:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005040:	fe1fe0ef          	jal	80004020 <filealloc>
    80005044:	892a                	mv	s2,a0
    80005046:	c179                	beqz	a0,8000510c <sys_open+0x12c>
    80005048:	ed4e                	sd	s3,152(sp)
    8000504a:	a43ff0ef          	jal	80004a8c <fdalloc>
    8000504e:	89aa                	mv	s3,a0
    80005050:	0a054a63          	bltz	a0,80005104 <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005054:	04449703          	lh	a4,68(s1)
    80005058:	478d                	li	a5,3
    8000505a:	0cf70263          	beq	a4,a5,8000511e <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000505e:	4789                	li	a5,2
    80005060:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005064:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005068:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000506c:	f4c42783          	lw	a5,-180(s0)
    80005070:	0017c713          	xori	a4,a5,1
    80005074:	8b05                	andi	a4,a4,1
    80005076:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000507a:	0037f713          	andi	a4,a5,3
    8000507e:	00e03733          	snez	a4,a4
    80005082:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005086:	4007f793          	andi	a5,a5,1024
    8000508a:	c791                	beqz	a5,80005096 <sys_open+0xb6>
    8000508c:	04449703          	lh	a4,68(s1)
    80005090:	4789                	li	a5,2
    80005092:	08f70d63          	beq	a4,a5,8000512c <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    80005096:	8526                	mv	a0,s1
    80005098:	ae4fe0ef          	jal	8000337c <iunlock>
  end_op();
    8000509c:	c87fe0ef          	jal	80003d22 <end_op>

  return fd;
    800050a0:	854e                	mv	a0,s3
    800050a2:	74aa                	ld	s1,168(sp)
    800050a4:	790a                	ld	s2,160(sp)
    800050a6:	69ea                	ld	s3,152(sp)
}
    800050a8:	70ea                	ld	ra,184(sp)
    800050aa:	744a                	ld	s0,176(sp)
    800050ac:	6129                	addi	sp,sp,192
    800050ae:	8082                	ret
      end_op();
    800050b0:	c73fe0ef          	jal	80003d22 <end_op>
      return -1;
    800050b4:	557d                	li	a0,-1
    800050b6:	74aa                	ld	s1,168(sp)
    800050b8:	bfc5                	j	800050a8 <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    800050ba:	f5040513          	addi	a0,s0,-176
    800050be:	a27fe0ef          	jal	80003ae4 <namei>
    800050c2:	84aa                	mv	s1,a0
    800050c4:	c11d                	beqz	a0,800050ea <sys_open+0x10a>
    ilock(ip);
    800050c6:	a08fe0ef          	jal	800032ce <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800050ca:	04449703          	lh	a4,68(s1)
    800050ce:	4785                	li	a5,1
    800050d0:	f4f71de3          	bne	a4,a5,8000502a <sys_open+0x4a>
    800050d4:	f4c42783          	lw	a5,-180(s0)
    800050d8:	d3bd                	beqz	a5,8000503e <sys_open+0x5e>
      iunlockput(ip);
    800050da:	8526                	mv	a0,s1
    800050dc:	bfcfe0ef          	jal	800034d8 <iunlockput>
      end_op();
    800050e0:	c43fe0ef          	jal	80003d22 <end_op>
      return -1;
    800050e4:	557d                	li	a0,-1
    800050e6:	74aa                	ld	s1,168(sp)
    800050e8:	b7c1                	j	800050a8 <sys_open+0xc8>
      end_op();
    800050ea:	c39fe0ef          	jal	80003d22 <end_op>
      return -1;
    800050ee:	557d                	li	a0,-1
    800050f0:	74aa                	ld	s1,168(sp)
    800050f2:	bf5d                	j	800050a8 <sys_open+0xc8>
    iunlockput(ip);
    800050f4:	8526                	mv	a0,s1
    800050f6:	be2fe0ef          	jal	800034d8 <iunlockput>
    end_op();
    800050fa:	c29fe0ef          	jal	80003d22 <end_op>
    return -1;
    800050fe:	557d                	li	a0,-1
    80005100:	74aa                	ld	s1,168(sp)
    80005102:	b75d                	j	800050a8 <sys_open+0xc8>
      fileclose(f);
    80005104:	854a                	mv	a0,s2
    80005106:	fbffe0ef          	jal	800040c4 <fileclose>
    8000510a:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    8000510c:	8526                	mv	a0,s1
    8000510e:	bcafe0ef          	jal	800034d8 <iunlockput>
    end_op();
    80005112:	c11fe0ef          	jal	80003d22 <end_op>
    return -1;
    80005116:	557d                	li	a0,-1
    80005118:	74aa                	ld	s1,168(sp)
    8000511a:	790a                	ld	s2,160(sp)
    8000511c:	b771                	j	800050a8 <sys_open+0xc8>
    f->type = FD_DEVICE;
    8000511e:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005122:	04649783          	lh	a5,70(s1)
    80005126:	02f91223          	sh	a5,36(s2)
    8000512a:	bf3d                	j	80005068 <sys_open+0x88>
    itrunc(ip);
    8000512c:	8526                	mv	a0,s1
    8000512e:	a8efe0ef          	jal	800033bc <itrunc>
    80005132:	b795                	j	80005096 <sys_open+0xb6>

0000000080005134 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005134:	7175                	addi	sp,sp,-144
    80005136:	e506                	sd	ra,136(sp)
    80005138:	e122                	sd	s0,128(sp)
    8000513a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000513c:	b7dfe0ef          	jal	80003cb8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005140:	08000613          	li	a2,128
    80005144:	f7040593          	addi	a1,s0,-144
    80005148:	4501                	li	a0,0
    8000514a:	f9afd0ef          	jal	800028e4 <argstr>
    8000514e:	02054363          	bltz	a0,80005174 <sys_mkdir+0x40>
    80005152:	4681                	li	a3,0
    80005154:	4601                	li	a2,0
    80005156:	4585                	li	a1,1
    80005158:	f7040513          	addi	a0,s0,-144
    8000515c:	96fff0ef          	jal	80004aca <create>
    80005160:	c911                	beqz	a0,80005174 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005162:	b76fe0ef          	jal	800034d8 <iunlockput>
  end_op();
    80005166:	bbdfe0ef          	jal	80003d22 <end_op>
  return 0;
    8000516a:	4501                	li	a0,0
}
    8000516c:	60aa                	ld	ra,136(sp)
    8000516e:	640a                	ld	s0,128(sp)
    80005170:	6149                	addi	sp,sp,144
    80005172:	8082                	ret
    end_op();
    80005174:	baffe0ef          	jal	80003d22 <end_op>
    return -1;
    80005178:	557d                	li	a0,-1
    8000517a:	bfcd                	j	8000516c <sys_mkdir+0x38>

000000008000517c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000517c:	7135                	addi	sp,sp,-160
    8000517e:	ed06                	sd	ra,152(sp)
    80005180:	e922                	sd	s0,144(sp)
    80005182:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005184:	b35fe0ef          	jal	80003cb8 <begin_op>
  argint(1, &major);
    80005188:	f6c40593          	addi	a1,s0,-148
    8000518c:	4505                	li	a0,1
    8000518e:	f1efd0ef          	jal	800028ac <argint>
  argint(2, &minor);
    80005192:	f6840593          	addi	a1,s0,-152
    80005196:	4509                	li	a0,2
    80005198:	f14fd0ef          	jal	800028ac <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000519c:	08000613          	li	a2,128
    800051a0:	f7040593          	addi	a1,s0,-144
    800051a4:	4501                	li	a0,0
    800051a6:	f3efd0ef          	jal	800028e4 <argstr>
    800051aa:	02054563          	bltz	a0,800051d4 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800051ae:	f6841683          	lh	a3,-152(s0)
    800051b2:	f6c41603          	lh	a2,-148(s0)
    800051b6:	458d                	li	a1,3
    800051b8:	f7040513          	addi	a0,s0,-144
    800051bc:	90fff0ef          	jal	80004aca <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800051c0:	c911                	beqz	a0,800051d4 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800051c2:	b16fe0ef          	jal	800034d8 <iunlockput>
  end_op();
    800051c6:	b5dfe0ef          	jal	80003d22 <end_op>
  return 0;
    800051ca:	4501                	li	a0,0
}
    800051cc:	60ea                	ld	ra,152(sp)
    800051ce:	644a                	ld	s0,144(sp)
    800051d0:	610d                	addi	sp,sp,160
    800051d2:	8082                	ret
    end_op();
    800051d4:	b4ffe0ef          	jal	80003d22 <end_op>
    return -1;
    800051d8:	557d                	li	a0,-1
    800051da:	bfcd                	j	800051cc <sys_mknod+0x50>

00000000800051dc <sys_chdir>:

uint64
sys_chdir(void)
{
    800051dc:	7135                	addi	sp,sp,-160
    800051de:	ed06                	sd	ra,152(sp)
    800051e0:	e922                	sd	s0,144(sp)
    800051e2:	e14a                	sd	s2,128(sp)
    800051e4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800051e6:	ee8fc0ef          	jal	800018ce <myproc>
    800051ea:	892a                	mv	s2,a0
  
  begin_op();
    800051ec:	acdfe0ef          	jal	80003cb8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800051f0:	08000613          	li	a2,128
    800051f4:	f6040593          	addi	a1,s0,-160
    800051f8:	4501                	li	a0,0
    800051fa:	eeafd0ef          	jal	800028e4 <argstr>
    800051fe:	04054363          	bltz	a0,80005244 <sys_chdir+0x68>
    80005202:	e526                	sd	s1,136(sp)
    80005204:	f6040513          	addi	a0,s0,-160
    80005208:	8ddfe0ef          	jal	80003ae4 <namei>
    8000520c:	84aa                	mv	s1,a0
    8000520e:	c915                	beqz	a0,80005242 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005210:	8befe0ef          	jal	800032ce <ilock>
  if(ip->type != T_DIR){
    80005214:	04449703          	lh	a4,68(s1)
    80005218:	4785                	li	a5,1
    8000521a:	02f71963          	bne	a4,a5,8000524c <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000521e:	8526                	mv	a0,s1
    80005220:	95cfe0ef          	jal	8000337c <iunlock>
  iput(p->cwd);
    80005224:	16893503          	ld	a0,360(s2)
    80005228:	a28fe0ef          	jal	80003450 <iput>
  end_op();
    8000522c:	af7fe0ef          	jal	80003d22 <end_op>
  p->cwd = ip;
    80005230:	16993423          	sd	s1,360(s2)
  return 0;
    80005234:	4501                	li	a0,0
    80005236:	64aa                	ld	s1,136(sp)
}
    80005238:	60ea                	ld	ra,152(sp)
    8000523a:	644a                	ld	s0,144(sp)
    8000523c:	690a                	ld	s2,128(sp)
    8000523e:	610d                	addi	sp,sp,160
    80005240:	8082                	ret
    80005242:	64aa                	ld	s1,136(sp)
    end_op();
    80005244:	adffe0ef          	jal	80003d22 <end_op>
    return -1;
    80005248:	557d                	li	a0,-1
    8000524a:	b7fd                	j	80005238 <sys_chdir+0x5c>
    iunlockput(ip);
    8000524c:	8526                	mv	a0,s1
    8000524e:	a8afe0ef          	jal	800034d8 <iunlockput>
    end_op();
    80005252:	ad1fe0ef          	jal	80003d22 <end_op>
    return -1;
    80005256:	557d                	li	a0,-1
    80005258:	64aa                	ld	s1,136(sp)
    8000525a:	bff9                	j	80005238 <sys_chdir+0x5c>

000000008000525c <sys_exec>:

uint64
sys_exec(void)
{
    8000525c:	7121                	addi	sp,sp,-448
    8000525e:	ff06                	sd	ra,440(sp)
    80005260:	fb22                	sd	s0,432(sp)
    80005262:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005264:	e4840593          	addi	a1,s0,-440
    80005268:	4505                	li	a0,1
    8000526a:	e5efd0ef          	jal	800028c8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000526e:	08000613          	li	a2,128
    80005272:	f5040593          	addi	a1,s0,-176
    80005276:	4501                	li	a0,0
    80005278:	e6cfd0ef          	jal	800028e4 <argstr>
    8000527c:	87aa                	mv	a5,a0
    return -1;
    8000527e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005280:	0c07c463          	bltz	a5,80005348 <sys_exec+0xec>
    80005284:	f726                	sd	s1,424(sp)
    80005286:	f34a                	sd	s2,416(sp)
    80005288:	ef4e                	sd	s3,408(sp)
    8000528a:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    8000528c:	10000613          	li	a2,256
    80005290:	4581                	li	a1,0
    80005292:	e5040513          	addi	a0,s0,-432
    80005296:	a0dfb0ef          	jal	80000ca2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000529a:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    8000529e:	89a6                	mv	s3,s1
    800052a0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800052a2:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800052a6:	00391513          	slli	a0,s2,0x3
    800052aa:	e4040593          	addi	a1,s0,-448
    800052ae:	e4843783          	ld	a5,-440(s0)
    800052b2:	953e                	add	a0,a0,a5
    800052b4:	d6efd0ef          	jal	80002822 <fetchaddr>
    800052b8:	02054663          	bltz	a0,800052e4 <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    800052bc:	e4043783          	ld	a5,-448(s0)
    800052c0:	c3a9                	beqz	a5,80005302 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800052c2:	83dfb0ef          	jal	80000afe <kalloc>
    800052c6:	85aa                	mv	a1,a0
    800052c8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800052cc:	cd01                	beqz	a0,800052e4 <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800052ce:	6605                	lui	a2,0x1
    800052d0:	e4043503          	ld	a0,-448(s0)
    800052d4:	d98fd0ef          	jal	8000286c <fetchstr>
    800052d8:	00054663          	bltz	a0,800052e4 <sys_exec+0x88>
    if(i >= NELEM(argv)){
    800052dc:	0905                	addi	s2,s2,1
    800052de:	09a1                	addi	s3,s3,8
    800052e0:	fd4913e3          	bne	s2,s4,800052a6 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800052e4:	f5040913          	addi	s2,s0,-176
    800052e8:	6088                	ld	a0,0(s1)
    800052ea:	c931                	beqz	a0,8000533e <sys_exec+0xe2>
    kfree(argv[i]);
    800052ec:	f30fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800052f0:	04a1                	addi	s1,s1,8
    800052f2:	ff249be3          	bne	s1,s2,800052e8 <sys_exec+0x8c>
  return -1;
    800052f6:	557d                	li	a0,-1
    800052f8:	74ba                	ld	s1,424(sp)
    800052fa:	791a                	ld	s2,416(sp)
    800052fc:	69fa                	ld	s3,408(sp)
    800052fe:	6a5a                	ld	s4,400(sp)
    80005300:	a0a1                	j	80005348 <sys_exec+0xec>
      argv[i] = 0;
    80005302:	0009079b          	sext.w	a5,s2
    80005306:	078e                	slli	a5,a5,0x3
    80005308:	fd078793          	addi	a5,a5,-48
    8000530c:	97a2                	add	a5,a5,s0
    8000530e:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    80005312:	e5040593          	addi	a1,s0,-432
    80005316:	f5040513          	addi	a0,s0,-176
    8000531a:	ba8ff0ef          	jal	800046c2 <kexec>
    8000531e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005320:	f5040993          	addi	s3,s0,-176
    80005324:	6088                	ld	a0,0(s1)
    80005326:	c511                	beqz	a0,80005332 <sys_exec+0xd6>
    kfree(argv[i]);
    80005328:	ef4fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000532c:	04a1                	addi	s1,s1,8
    8000532e:	ff349be3          	bne	s1,s3,80005324 <sys_exec+0xc8>
  return ret;
    80005332:	854a                	mv	a0,s2
    80005334:	74ba                	ld	s1,424(sp)
    80005336:	791a                	ld	s2,416(sp)
    80005338:	69fa                	ld	s3,408(sp)
    8000533a:	6a5a                	ld	s4,400(sp)
    8000533c:	a031                	j	80005348 <sys_exec+0xec>
  return -1;
    8000533e:	557d                	li	a0,-1
    80005340:	74ba                	ld	s1,424(sp)
    80005342:	791a                	ld	s2,416(sp)
    80005344:	69fa                	ld	s3,408(sp)
    80005346:	6a5a                	ld	s4,400(sp)
}
    80005348:	70fa                	ld	ra,440(sp)
    8000534a:	745a                	ld	s0,432(sp)
    8000534c:	6139                	addi	sp,sp,448
    8000534e:	8082                	ret

0000000080005350 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005350:	7139                	addi	sp,sp,-64
    80005352:	fc06                	sd	ra,56(sp)
    80005354:	f822                	sd	s0,48(sp)
    80005356:	f426                	sd	s1,40(sp)
    80005358:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000535a:	d74fc0ef          	jal	800018ce <myproc>
    8000535e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005360:	fd840593          	addi	a1,s0,-40
    80005364:	4501                	li	a0,0
    80005366:	d62fd0ef          	jal	800028c8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000536a:	fc840593          	addi	a1,s0,-56
    8000536e:	fd040513          	addi	a0,s0,-48
    80005372:	85cff0ef          	jal	800043ce <pipealloc>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005378:	0a054463          	bltz	a0,80005420 <sys_pipe+0xd0>
  fd0 = -1;
    8000537c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005380:	fd043503          	ld	a0,-48(s0)
    80005384:	f08ff0ef          	jal	80004a8c <fdalloc>
    80005388:	fca42223          	sw	a0,-60(s0)
    8000538c:	08054163          	bltz	a0,8000540e <sys_pipe+0xbe>
    80005390:	fc843503          	ld	a0,-56(s0)
    80005394:	ef8ff0ef          	jal	80004a8c <fdalloc>
    80005398:	fca42023          	sw	a0,-64(s0)
    8000539c:	06054063          	bltz	a0,800053fc <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800053a0:	4691                	li	a3,4
    800053a2:	fc440613          	addi	a2,s0,-60
    800053a6:	fd843583          	ld	a1,-40(s0)
    800053aa:	74a8                	ld	a0,104(s1)
    800053ac:	a36fc0ef          	jal	800015e2 <copyout>
    800053b0:	00054e63          	bltz	a0,800053cc <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800053b4:	4691                	li	a3,4
    800053b6:	fc040613          	addi	a2,s0,-64
    800053ba:	fd843583          	ld	a1,-40(s0)
    800053be:	0591                	addi	a1,a1,4
    800053c0:	74a8                	ld	a0,104(s1)
    800053c2:	a20fc0ef          	jal	800015e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800053c6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800053c8:	04055c63          	bgez	a0,80005420 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    800053cc:	fc442783          	lw	a5,-60(s0)
    800053d0:	07f1                	addi	a5,a5,28
    800053d2:	078e                	slli	a5,a5,0x3
    800053d4:	97a6                	add	a5,a5,s1
    800053d6:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800053da:	fc042783          	lw	a5,-64(s0)
    800053de:	07f1                	addi	a5,a5,28
    800053e0:	078e                	slli	a5,a5,0x3
    800053e2:	94be                	add	s1,s1,a5
    800053e4:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    800053e8:	fd043503          	ld	a0,-48(s0)
    800053ec:	cd9fe0ef          	jal	800040c4 <fileclose>
    fileclose(wf);
    800053f0:	fc843503          	ld	a0,-56(s0)
    800053f4:	cd1fe0ef          	jal	800040c4 <fileclose>
    return -1;
    800053f8:	57fd                	li	a5,-1
    800053fa:	a01d                	j	80005420 <sys_pipe+0xd0>
    if(fd0 >= 0)
    800053fc:	fc442783          	lw	a5,-60(s0)
    80005400:	0007c763          	bltz	a5,8000540e <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005404:	07f1                	addi	a5,a5,28
    80005406:	078e                	slli	a5,a5,0x3
    80005408:	97a6                	add	a5,a5,s1
    8000540a:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    8000540e:	fd043503          	ld	a0,-48(s0)
    80005412:	cb3fe0ef          	jal	800040c4 <fileclose>
    fileclose(wf);
    80005416:	fc843503          	ld	a0,-56(s0)
    8000541a:	cabfe0ef          	jal	800040c4 <fileclose>
    return -1;
    8000541e:	57fd                	li	a5,-1
}
    80005420:	853e                	mv	a0,a5
    80005422:	70e2                	ld	ra,56(sp)
    80005424:	7442                	ld	s0,48(sp)
    80005426:	74a2                	ld	s1,40(sp)
    80005428:	6121                	addi	sp,sp,64
    8000542a:	8082                	ret
    8000542c:	0000                	unimp
	...

0000000080005430 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005430:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005432:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005434:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005436:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005438:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000543a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000543c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000543e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005440:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005442:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005444:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005446:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005448:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000544a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000544c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000544e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005450:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005452:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005454:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005456:	adcfd0ef          	jal	80002732 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000545a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000545c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000545e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80005460:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80005462:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    80005464:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80005466:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80005468:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000546a:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    8000546c:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    8000546e:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005470:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005472:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005474:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005476:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005478:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000547a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000547c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000547e:	10200073          	sret
	...

000000008000548e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000548e:	1141                	addi	sp,sp,-16
    80005490:	e422                	sd	s0,8(sp)
    80005492:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005494:	0c0007b7          	lui	a5,0xc000
    80005498:	4705                	li	a4,1
    8000549a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000549c:	0c0007b7          	lui	a5,0xc000
    800054a0:	c3d8                	sw	a4,4(a5)
}
    800054a2:	6422                	ld	s0,8(sp)
    800054a4:	0141                	addi	sp,sp,16
    800054a6:	8082                	ret

00000000800054a8 <plicinithart>:

void
plicinithart(void)
{
    800054a8:	1141                	addi	sp,sp,-16
    800054aa:	e406                	sd	ra,8(sp)
    800054ac:	e022                	sd	s0,0(sp)
    800054ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800054b0:	bf2fc0ef          	jal	800018a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800054b4:	0085171b          	slliw	a4,a0,0x8
    800054b8:	0c0027b7          	lui	a5,0xc002
    800054bc:	97ba                	add	a5,a5,a4
    800054be:	40200713          	li	a4,1026
    800054c2:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800054c6:	00d5151b          	slliw	a0,a0,0xd
    800054ca:	0c2017b7          	lui	a5,0xc201
    800054ce:	97aa                	add	a5,a5,a0
    800054d0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800054d4:	60a2                	ld	ra,8(sp)
    800054d6:	6402                	ld	s0,0(sp)
    800054d8:	0141                	addi	sp,sp,16
    800054da:	8082                	ret

00000000800054dc <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800054dc:	1141                	addi	sp,sp,-16
    800054de:	e406                	sd	ra,8(sp)
    800054e0:	e022                	sd	s0,0(sp)
    800054e2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800054e4:	bbefc0ef          	jal	800018a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800054e8:	00d5151b          	slliw	a0,a0,0xd
    800054ec:	0c2017b7          	lui	a5,0xc201
    800054f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800054f2:	43c8                	lw	a0,4(a5)
    800054f4:	60a2                	ld	ra,8(sp)
    800054f6:	6402                	ld	s0,0(sp)
    800054f8:	0141                	addi	sp,sp,16
    800054fa:	8082                	ret

00000000800054fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800054fc:	1101                	addi	sp,sp,-32
    800054fe:	ec06                	sd	ra,24(sp)
    80005500:	e822                	sd	s0,16(sp)
    80005502:	e426                	sd	s1,8(sp)
    80005504:	1000                	addi	s0,sp,32
    80005506:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005508:	b9afc0ef          	jal	800018a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000550c:	00d5151b          	slliw	a0,a0,0xd
    80005510:	0c2017b7          	lui	a5,0xc201
    80005514:	97aa                	add	a5,a5,a0
    80005516:	c3c4                	sw	s1,4(a5)
}
    80005518:	60e2                	ld	ra,24(sp)
    8000551a:	6442                	ld	s0,16(sp)
    8000551c:	64a2                	ld	s1,8(sp)
    8000551e:	6105                	addi	sp,sp,32
    80005520:	8082                	ret

0000000080005522 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005522:	1141                	addi	sp,sp,-16
    80005524:	e406                	sd	ra,8(sp)
    80005526:	e022                	sd	s0,0(sp)
    80005528:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000552a:	479d                	li	a5,7
    8000552c:	04a7ca63          	blt	a5,a0,80005580 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005530:	0001c797          	auipc	a5,0x1c
    80005534:	b6878793          	addi	a5,a5,-1176 # 80021098 <disk>
    80005538:	97aa                	add	a5,a5,a0
    8000553a:	0187c783          	lbu	a5,24(a5)
    8000553e:	e7b9                	bnez	a5,8000558c <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005540:	00451693          	slli	a3,a0,0x4
    80005544:	0001c797          	auipc	a5,0x1c
    80005548:	b5478793          	addi	a5,a5,-1196 # 80021098 <disk>
    8000554c:	6398                	ld	a4,0(a5)
    8000554e:	9736                	add	a4,a4,a3
    80005550:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005554:	6398                	ld	a4,0(a5)
    80005556:	9736                	add	a4,a4,a3
    80005558:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    8000555c:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005560:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005564:	97aa                	add	a5,a5,a0
    80005566:	4705                	li	a4,1
    80005568:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    8000556c:	0001c517          	auipc	a0,0x1c
    80005570:	b4450513          	addi	a0,a0,-1212 # 800210b0 <disk+0x18>
    80005574:	a5ffc0ef          	jal	80001fd2 <wakeup>
}
    80005578:	60a2                	ld	ra,8(sp)
    8000557a:	6402                	ld	s0,0(sp)
    8000557c:	0141                	addi	sp,sp,16
    8000557e:	8082                	ret
    panic("free_desc 1");
    80005580:	00002517          	auipc	a0,0x2
    80005584:	0d850513          	addi	a0,a0,216 # 80007658 <etext+0x658>
    80005588:	a58fb0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    8000558c:	00002517          	auipc	a0,0x2
    80005590:	0dc50513          	addi	a0,a0,220 # 80007668 <etext+0x668>
    80005594:	a4cfb0ef          	jal	800007e0 <panic>

0000000080005598 <virtio_disk_init>:
{
    80005598:	1101                	addi	sp,sp,-32
    8000559a:	ec06                	sd	ra,24(sp)
    8000559c:	e822                	sd	s0,16(sp)
    8000559e:	e426                	sd	s1,8(sp)
    800055a0:	e04a                	sd	s2,0(sp)
    800055a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800055a4:	00002597          	auipc	a1,0x2
    800055a8:	0d458593          	addi	a1,a1,212 # 80007678 <etext+0x678>
    800055ac:	0001c517          	auipc	a0,0x1c
    800055b0:	c1450513          	addi	a0,a0,-1004 # 800211c0 <disk+0x128>
    800055b4:	d9afb0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800055b8:	100017b7          	lui	a5,0x10001
    800055bc:	4398                	lw	a4,0(a5)
    800055be:	2701                	sext.w	a4,a4
    800055c0:	747277b7          	lui	a5,0x74727
    800055c4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800055c8:	18f71063          	bne	a4,a5,80005748 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800055cc:	100017b7          	lui	a5,0x10001
    800055d0:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    800055d2:	439c                	lw	a5,0(a5)
    800055d4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800055d6:	4709                	li	a4,2
    800055d8:	16e79863          	bne	a5,a4,80005748 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800055dc:	100017b7          	lui	a5,0x10001
    800055e0:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    800055e2:	439c                	lw	a5,0(a5)
    800055e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800055e6:	16e79163          	bne	a5,a4,80005748 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800055ea:	100017b7          	lui	a5,0x10001
    800055ee:	47d8                	lw	a4,12(a5)
    800055f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800055f2:	554d47b7          	lui	a5,0x554d4
    800055f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800055fa:	14f71763          	bne	a4,a5,80005748 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    800055fe:	100017b7          	lui	a5,0x10001
    80005602:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005606:	4705                	li	a4,1
    80005608:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000560a:	470d                	li	a4,3
    8000560c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000560e:	10001737          	lui	a4,0x10001
    80005612:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005614:	c7ffe737          	lui	a4,0xc7ffe
    80005618:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdd587>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000561c:	8ef9                	and	a3,a3,a4
    8000561e:	10001737          	lui	a4,0x10001
    80005622:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005624:	472d                	li	a4,11
    80005626:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005628:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    8000562c:	439c                	lw	a5,0(a5)
    8000562e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005632:	8ba1                	andi	a5,a5,8
    80005634:	12078063          	beqz	a5,80005754 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005638:	100017b7          	lui	a5,0x10001
    8000563c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005640:	100017b7          	lui	a5,0x10001
    80005644:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80005648:	439c                	lw	a5,0(a5)
    8000564a:	2781                	sext.w	a5,a5
    8000564c:	10079a63          	bnez	a5,80005760 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005650:	100017b7          	lui	a5,0x10001
    80005654:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80005658:	439c                	lw	a5,0(a5)
    8000565a:	2781                	sext.w	a5,a5
  if(max == 0)
    8000565c:	10078863          	beqz	a5,8000576c <virtio_disk_init+0x1d4>
  if(max < NUM)
    80005660:	471d                	li	a4,7
    80005662:	10f77b63          	bgeu	a4,a5,80005778 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    80005666:	c98fb0ef          	jal	80000afe <kalloc>
    8000566a:	0001c497          	auipc	s1,0x1c
    8000566e:	a2e48493          	addi	s1,s1,-1490 # 80021098 <disk>
    80005672:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005674:	c8afb0ef          	jal	80000afe <kalloc>
    80005678:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000567a:	c84fb0ef          	jal	80000afe <kalloc>
    8000567e:	87aa                	mv	a5,a0
    80005680:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005682:	6088                	ld	a0,0(s1)
    80005684:	10050063          	beqz	a0,80005784 <virtio_disk_init+0x1ec>
    80005688:	0001c717          	auipc	a4,0x1c
    8000568c:	a1873703          	ld	a4,-1512(a4) # 800210a0 <disk+0x8>
    80005690:	0e070a63          	beqz	a4,80005784 <virtio_disk_init+0x1ec>
    80005694:	0e078863          	beqz	a5,80005784 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80005698:	6605                	lui	a2,0x1
    8000569a:	4581                	li	a1,0
    8000569c:	e06fb0ef          	jal	80000ca2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800056a0:	0001c497          	auipc	s1,0x1c
    800056a4:	9f848493          	addi	s1,s1,-1544 # 80021098 <disk>
    800056a8:	6605                	lui	a2,0x1
    800056aa:	4581                	li	a1,0
    800056ac:	6488                	ld	a0,8(s1)
    800056ae:	df4fb0ef          	jal	80000ca2 <memset>
  memset(disk.used, 0, PGSIZE);
    800056b2:	6605                	lui	a2,0x1
    800056b4:	4581                	li	a1,0
    800056b6:	6888                	ld	a0,16(s1)
    800056b8:	deafb0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800056bc:	100017b7          	lui	a5,0x10001
    800056c0:	4721                	li	a4,8
    800056c2:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800056c4:	4098                	lw	a4,0(s1)
    800056c6:	100017b7          	lui	a5,0x10001
    800056ca:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800056ce:	40d8                	lw	a4,4(s1)
    800056d0:	100017b7          	lui	a5,0x10001
    800056d4:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800056d8:	649c                	ld	a5,8(s1)
    800056da:	0007869b          	sext.w	a3,a5
    800056de:	10001737          	lui	a4,0x10001
    800056e2:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800056e6:	9781                	srai	a5,a5,0x20
    800056e8:	10001737          	lui	a4,0x10001
    800056ec:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800056f0:	689c                	ld	a5,16(s1)
    800056f2:	0007869b          	sext.w	a3,a5
    800056f6:	10001737          	lui	a4,0x10001
    800056fa:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800056fe:	9781                	srai	a5,a5,0x20
    80005700:	10001737          	lui	a4,0x10001
    80005704:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005708:	10001737          	lui	a4,0x10001
    8000570c:	4785                	li	a5,1
    8000570e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80005710:	00f48c23          	sb	a5,24(s1)
    80005714:	00f48ca3          	sb	a5,25(s1)
    80005718:	00f48d23          	sb	a5,26(s1)
    8000571c:	00f48da3          	sb	a5,27(s1)
    80005720:	00f48e23          	sb	a5,28(s1)
    80005724:	00f48ea3          	sb	a5,29(s1)
    80005728:	00f48f23          	sb	a5,30(s1)
    8000572c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005730:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005734:	100017b7          	lui	a5,0x10001
    80005738:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    8000573c:	60e2                	ld	ra,24(sp)
    8000573e:	6442                	ld	s0,16(sp)
    80005740:	64a2                	ld	s1,8(sp)
    80005742:	6902                	ld	s2,0(sp)
    80005744:	6105                	addi	sp,sp,32
    80005746:	8082                	ret
    panic("could not find virtio disk");
    80005748:	00002517          	auipc	a0,0x2
    8000574c:	f4050513          	addi	a0,a0,-192 # 80007688 <etext+0x688>
    80005750:	890fb0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005754:	00002517          	auipc	a0,0x2
    80005758:	f5450513          	addi	a0,a0,-172 # 800076a8 <etext+0x6a8>
    8000575c:	884fb0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    80005760:	00002517          	auipc	a0,0x2
    80005764:	f6850513          	addi	a0,a0,-152 # 800076c8 <etext+0x6c8>
    80005768:	878fb0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    8000576c:	00002517          	auipc	a0,0x2
    80005770:	f7c50513          	addi	a0,a0,-132 # 800076e8 <etext+0x6e8>
    80005774:	86cfb0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    80005778:	00002517          	auipc	a0,0x2
    8000577c:	f9050513          	addi	a0,a0,-112 # 80007708 <etext+0x708>
    80005780:	860fb0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    80005784:	00002517          	auipc	a0,0x2
    80005788:	fa450513          	addi	a0,a0,-92 # 80007728 <etext+0x728>
    8000578c:	854fb0ef          	jal	800007e0 <panic>

0000000080005790 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005790:	7159                	addi	sp,sp,-112
    80005792:	f486                	sd	ra,104(sp)
    80005794:	f0a2                	sd	s0,96(sp)
    80005796:	eca6                	sd	s1,88(sp)
    80005798:	e8ca                	sd	s2,80(sp)
    8000579a:	e4ce                	sd	s3,72(sp)
    8000579c:	e0d2                	sd	s4,64(sp)
    8000579e:	fc56                	sd	s5,56(sp)
    800057a0:	f85a                	sd	s6,48(sp)
    800057a2:	f45e                	sd	s7,40(sp)
    800057a4:	f062                	sd	s8,32(sp)
    800057a6:	ec66                	sd	s9,24(sp)
    800057a8:	1880                	addi	s0,sp,112
    800057aa:	8a2a                	mv	s4,a0
    800057ac:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800057ae:	00c52c83          	lw	s9,12(a0)
    800057b2:	001c9c9b          	slliw	s9,s9,0x1
    800057b6:	1c82                	slli	s9,s9,0x20
    800057b8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800057bc:	0001c517          	auipc	a0,0x1c
    800057c0:	a0450513          	addi	a0,a0,-1532 # 800211c0 <disk+0x128>
    800057c4:	c0afb0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    800057c8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800057ca:	44a1                	li	s1,8
      disk.free[i] = 0;
    800057cc:	0001cb17          	auipc	s6,0x1c
    800057d0:	8ccb0b13          	addi	s6,s6,-1844 # 80021098 <disk>
  for(int i = 0; i < 3; i++){
    800057d4:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800057d6:	0001cc17          	auipc	s8,0x1c
    800057da:	9eac0c13          	addi	s8,s8,-1558 # 800211c0 <disk+0x128>
    800057de:	a8b9                	j	8000583c <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    800057e0:	00fb0733          	add	a4,s6,a5
    800057e4:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    800057e8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800057ea:	0207c563          	bltz	a5,80005814 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    800057ee:	2905                	addiw	s2,s2,1
    800057f0:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800057f2:	05590963          	beq	s2,s5,80005844 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    800057f6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800057f8:	0001c717          	auipc	a4,0x1c
    800057fc:	8a070713          	addi	a4,a4,-1888 # 80021098 <disk>
    80005800:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005802:	01874683          	lbu	a3,24(a4)
    80005806:	fee9                	bnez	a3,800057e0 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005808:	2785                	addiw	a5,a5,1
    8000580a:	0705                	addi	a4,a4,1
    8000580c:	fe979be3          	bne	a5,s1,80005802 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005810:	57fd                	li	a5,-1
    80005812:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005814:	01205d63          	blez	s2,8000582e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005818:	f9042503          	lw	a0,-112(s0)
    8000581c:	d07ff0ef          	jal	80005522 <free_desc>
      for(int j = 0; j < i; j++)
    80005820:	4785                	li	a5,1
    80005822:	0127d663          	bge	a5,s2,8000582e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005826:	f9442503          	lw	a0,-108(s0)
    8000582a:	cf9ff0ef          	jal	80005522 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000582e:	85e2                	mv	a1,s8
    80005830:	0001c517          	auipc	a0,0x1c
    80005834:	88050513          	addi	a0,a0,-1920 # 800210b0 <disk+0x18>
    80005838:	f4efc0ef          	jal	80001f86 <sleep>
  for(int i = 0; i < 3; i++){
    8000583c:	f9040613          	addi	a2,s0,-112
    80005840:	894e                	mv	s2,s3
    80005842:	bf55                	j	800057f6 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005844:	f9042503          	lw	a0,-112(s0)
    80005848:	00451693          	slli	a3,a0,0x4

  if(write)
    8000584c:	0001c797          	auipc	a5,0x1c
    80005850:	84c78793          	addi	a5,a5,-1972 # 80021098 <disk>
    80005854:	00a50713          	addi	a4,a0,10
    80005858:	0712                	slli	a4,a4,0x4
    8000585a:	973e                	add	a4,a4,a5
    8000585c:	01703633          	snez	a2,s7
    80005860:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005862:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005866:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000586a:	6398                	ld	a4,0(a5)
    8000586c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000586e:	0a868613          	addi	a2,a3,168
    80005872:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005874:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005876:	6390                	ld	a2,0(a5)
    80005878:	00d605b3          	add	a1,a2,a3
    8000587c:	4741                	li	a4,16
    8000587e:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005880:	4805                	li	a6,1
    80005882:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80005886:	f9442703          	lw	a4,-108(s0)
    8000588a:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000588e:	0712                	slli	a4,a4,0x4
    80005890:	963a                	add	a2,a2,a4
    80005892:	058a0593          	addi	a1,s4,88
    80005896:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005898:	0007b883          	ld	a7,0(a5)
    8000589c:	9746                	add	a4,a4,a7
    8000589e:	40000613          	li	a2,1024
    800058a2:	c710                	sw	a2,8(a4)
  if(write)
    800058a4:	001bb613          	seqz	a2,s7
    800058a8:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800058ac:	00166613          	ori	a2,a2,1
    800058b0:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800058b4:	f9842583          	lw	a1,-104(s0)
    800058b8:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800058bc:	00250613          	addi	a2,a0,2
    800058c0:	0612                	slli	a2,a2,0x4
    800058c2:	963e                	add	a2,a2,a5
    800058c4:	577d                	li	a4,-1
    800058c6:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800058ca:	0592                	slli	a1,a1,0x4
    800058cc:	98ae                	add	a7,a7,a1
    800058ce:	03068713          	addi	a4,a3,48
    800058d2:	973e                	add	a4,a4,a5
    800058d4:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    800058d8:	6398                	ld	a4,0(a5)
    800058da:	972e                	add	a4,a4,a1
    800058dc:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800058e0:	4689                	li	a3,2
    800058e2:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    800058e6:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800058ea:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    800058ee:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800058f2:	6794                	ld	a3,8(a5)
    800058f4:	0026d703          	lhu	a4,2(a3)
    800058f8:	8b1d                	andi	a4,a4,7
    800058fa:	0706                	slli	a4,a4,0x1
    800058fc:	96ba                	add	a3,a3,a4
    800058fe:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005902:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005906:	6798                	ld	a4,8(a5)
    80005908:	00275783          	lhu	a5,2(a4)
    8000590c:	2785                	addiw	a5,a5,1
    8000590e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005912:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005916:	100017b7          	lui	a5,0x10001
    8000591a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000591e:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005922:	0001c917          	auipc	s2,0x1c
    80005926:	89e90913          	addi	s2,s2,-1890 # 800211c0 <disk+0x128>
  while(b->disk == 1) {
    8000592a:	4485                	li	s1,1
    8000592c:	01079a63          	bne	a5,a6,80005940 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80005930:	85ca                	mv	a1,s2
    80005932:	8552                	mv	a0,s4
    80005934:	e52fc0ef          	jal	80001f86 <sleep>
  while(b->disk == 1) {
    80005938:	004a2783          	lw	a5,4(s4)
    8000593c:	fe978ae3          	beq	a5,s1,80005930 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    80005940:	f9042903          	lw	s2,-112(s0)
    80005944:	00290713          	addi	a4,s2,2
    80005948:	0712                	slli	a4,a4,0x4
    8000594a:	0001b797          	auipc	a5,0x1b
    8000594e:	74e78793          	addi	a5,a5,1870 # 80021098 <disk>
    80005952:	97ba                	add	a5,a5,a4
    80005954:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005958:	0001b997          	auipc	s3,0x1b
    8000595c:	74098993          	addi	s3,s3,1856 # 80021098 <disk>
    80005960:	00491713          	slli	a4,s2,0x4
    80005964:	0009b783          	ld	a5,0(s3)
    80005968:	97ba                	add	a5,a5,a4
    8000596a:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000596e:	854a                	mv	a0,s2
    80005970:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005974:	bafff0ef          	jal	80005522 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005978:	8885                	andi	s1,s1,1
    8000597a:	f0fd                	bnez	s1,80005960 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000597c:	0001c517          	auipc	a0,0x1c
    80005980:	84450513          	addi	a0,a0,-1980 # 800211c0 <disk+0x128>
    80005984:	ae2fb0ef          	jal	80000c66 <release>
}
    80005988:	70a6                	ld	ra,104(sp)
    8000598a:	7406                	ld	s0,96(sp)
    8000598c:	64e6                	ld	s1,88(sp)
    8000598e:	6946                	ld	s2,80(sp)
    80005990:	69a6                	ld	s3,72(sp)
    80005992:	6a06                	ld	s4,64(sp)
    80005994:	7ae2                	ld	s5,56(sp)
    80005996:	7b42                	ld	s6,48(sp)
    80005998:	7ba2                	ld	s7,40(sp)
    8000599a:	7c02                	ld	s8,32(sp)
    8000599c:	6ce2                	ld	s9,24(sp)
    8000599e:	6165                	addi	sp,sp,112
    800059a0:	8082                	ret

00000000800059a2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800059a2:	1101                	addi	sp,sp,-32
    800059a4:	ec06                	sd	ra,24(sp)
    800059a6:	e822                	sd	s0,16(sp)
    800059a8:	e426                	sd	s1,8(sp)
    800059aa:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800059ac:	0001b497          	auipc	s1,0x1b
    800059b0:	6ec48493          	addi	s1,s1,1772 # 80021098 <disk>
    800059b4:	0001c517          	auipc	a0,0x1c
    800059b8:	80c50513          	addi	a0,a0,-2036 # 800211c0 <disk+0x128>
    800059bc:	a12fb0ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800059c0:	100017b7          	lui	a5,0x10001
    800059c4:	53b8                	lw	a4,96(a5)
    800059c6:	8b0d                	andi	a4,a4,3
    800059c8:	100017b7          	lui	a5,0x10001
    800059cc:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    800059ce:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800059d2:	689c                	ld	a5,16(s1)
    800059d4:	0204d703          	lhu	a4,32(s1)
    800059d8:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    800059dc:	04f70663          	beq	a4,a5,80005a28 <virtio_disk_intr+0x86>
    __sync_synchronize();
    800059e0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800059e4:	6898                	ld	a4,16(s1)
    800059e6:	0204d783          	lhu	a5,32(s1)
    800059ea:	8b9d                	andi	a5,a5,7
    800059ec:	078e                	slli	a5,a5,0x3
    800059ee:	97ba                	add	a5,a5,a4
    800059f0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800059f2:	00278713          	addi	a4,a5,2
    800059f6:	0712                	slli	a4,a4,0x4
    800059f8:	9726                	add	a4,a4,s1
    800059fa:	01074703          	lbu	a4,16(a4)
    800059fe:	e321                	bnez	a4,80005a3e <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005a00:	0789                	addi	a5,a5,2
    80005a02:	0792                	slli	a5,a5,0x4
    80005a04:	97a6                	add	a5,a5,s1
    80005a06:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005a08:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005a0c:	dc6fc0ef          	jal	80001fd2 <wakeup>

    disk.used_idx += 1;
    80005a10:	0204d783          	lhu	a5,32(s1)
    80005a14:	2785                	addiw	a5,a5,1
    80005a16:	17c2                	slli	a5,a5,0x30
    80005a18:	93c1                	srli	a5,a5,0x30
    80005a1a:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005a1e:	6898                	ld	a4,16(s1)
    80005a20:	00275703          	lhu	a4,2(a4)
    80005a24:	faf71ee3          	bne	a4,a5,800059e0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005a28:	0001b517          	auipc	a0,0x1b
    80005a2c:	79850513          	addi	a0,a0,1944 # 800211c0 <disk+0x128>
    80005a30:	a36fb0ef          	jal	80000c66 <release>
}
    80005a34:	60e2                	ld	ra,24(sp)
    80005a36:	6442                	ld	s0,16(sp)
    80005a38:	64a2                	ld	s1,8(sp)
    80005a3a:	6105                	addi	sp,sp,32
    80005a3c:	8082                	ret
      panic("virtio_disk_intr status");
    80005a3e:	00002517          	auipc	a0,0x2
    80005a42:	d0250513          	addi	a0,a0,-766 # 80007740 <etext+0x740>
    80005a46:	d9bfa0ef          	jal	800007e0 <panic>
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0)
    80006010:	02253823          	sd	sp,48(a0)
    80006014:	02353c23          	sd	gp,56(a0)
    80006018:	04453023          	sd	tp,64(a0)
    8000601c:	04553423          	sd	t0,72(a0)
    80006020:	04653823          	sd	t1,80(a0)
    80006024:	04753c23          	sd	t2,88(a0)
    80006028:	f120                	sd	s0,96(a0)
    8000602a:	f524                	sd	s1,104(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
    8000602e:	e150                	sd	a2,128(a0)
    80006030:	e554                	sd	a3,136(a0)
    80006032:	e958                	sd	a4,144(a0)
    80006034:	ed5c                	sd	a5,152(a0)
    80006036:	0b053023          	sd	a6,160(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
    80006046:	0d453023          	sd	s4,192(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
    80006056:	0f853023          	sd	s8,224(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
    80006066:	11c53023          	sd	t3,256(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
    80006072:	11f53c23          	sd	t6,280(a0)
    80006076:	140022f3          	csrr	t0,sscratch
    8000607a:	06553823          	sd	t0,112(a0)
    8000607e:	00853103          	ld	sp,8(a0)
    80006082:	02053203          	ld	tp,32(a0)
    80006086:	01053283          	ld	t0,16(a0)
    8000608a:	00053303          	ld	t1,0(a0)
    8000608e:	12000073          	sfence.vma
    80006092:	18031073          	csrw	satp,t1
    80006096:	12000073          	sfence.vma
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
    8000609c:	12000073          	sfence.vma
    800060a0:	18051073          	csrw	satp,a0
    800060a4:	12000073          	sfence.vma
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0)
    800060b4:	03053103          	ld	sp,48(a0)
    800060b8:	03853183          	ld	gp,56(a0)
    800060bc:	04053203          	ld	tp,64(a0)
    800060c0:	04853283          	ld	t0,72(a0)
    800060c4:	05053303          	ld	t1,80(a0)
    800060c8:	05853383          	ld	t2,88(a0)
    800060cc:	7120                	ld	s0,96(a0)
    800060ce:	7524                	ld	s1,104(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
    800060d2:	6150                	ld	a2,128(a0)
    800060d4:	6554                	ld	a3,136(a0)
    800060d6:	6958                	ld	a4,144(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
    800060da:	0a053803          	ld	a6,160(a0)
    800060de:	0a853883          	ld	a7,168(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
    80006112:	11053f03          	ld	t5,272(a0)
    80006116:	11853f83          	ld	t6,280(a0)
    8000611a:	7928                	ld	a0,112(a0)
    8000611c:	10200073          	sret
	...
