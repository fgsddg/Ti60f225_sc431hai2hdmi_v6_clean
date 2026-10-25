
build/tinyml_style.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00007197          	auipc	gp,0x7
    1004:	b6018193          	addi	gp,gp,-1184 # 7b60 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	00007117          	auipc	sp,0x7
    100c:	57810113          	addi	sp,sp,1400 # 8580 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00005517          	auipc	a0,0x5
    1014:	c0850513          	addi	a0,a0,-1016 # 5c18 <_data>
	la a1, _data
    1018:	00005597          	auipc	a1,0x5
    101c:	c0058593          	addi	a1,a1,-1024 # 5c18 <_data>
	la a2, _edata
    1020:	00006617          	auipc	a2,0x6
    1024:	37460613          	addi	a2,a2,884 # 7394 <__bss_start>
	bgeu a1, a2, 2f
    1028:	00c5fc63          	bgeu	a1,a2,1040 <init+0x38>
1:
	lw t0, (a0)
    102c:	00052283          	lw	t0,0(a0)
	sw t0, (a1)
    1030:	0055a023          	sw	t0,0(a1)
	addi a0, a0, 4
    1034:	00450513          	addi	a0,a0,4
	addi a1, a1, 4
    1038:	00458593          	addi	a1,a1,4
	bltu a1, a2, 1b
    103c:	fec5e8e3          	bltu	a1,a2,102c <init+0x24>
2:

	/* Clear bss section */
	la a0, __bss_start
    1040:	00006517          	auipc	a0,0x6
    1044:	35450513          	addi	a0,a0,852 # 7394 <__bss_start>
	la a1, _end
    1048:	00006597          	auipc	a1,0x6
    104c:	53058593          	addi	a1,a1,1328 # 7578 <_end>
	bgeu a0, a1, 2f
    1050:	00b57863          	bgeu	a0,a1,1060 <init+0x58>
1:
	sw zero, (a0)
    1054:	00052023          	sw	zero,0(a0)
	addi a0, a0, 4
    1058:	00450513          	addi	a0,a0,4
	bltu a0, a1, 1b
    105c:	feb56ce3          	bltu	a0,a1,1054 <init+0x4c>
2:

#ifndef NO_LIBC_INIT_ARRAY
	call __libc_init_array
    1060:	018000ef          	jal	1078 <__libc_init_array>
#endif

	call main
    1064:	319010ef          	jal	2b7c <main>

00001068 <mainDone>:
mainDone:
    j mainDone
    1068:	0000006f          	j	1068 <mainDone>

0000106c <_init>:


	.globl _init
_init:
    ret
    106c:	00008067          	ret

Disassembly of section .text:

00001070 <__errno>:
    1070:	81c1a503          	lw	a0,-2020(gp) # 737c <_impure_ptr>
    1074:	00008067          	ret

00001078 <__libc_init_array>:
    1078:	ff010113          	addi	sp,sp,-16
    107c:	00812423          	sw	s0,8(sp)
    1080:	01212023          	sw	s2,0(sp)
    1084:	00005797          	auipc	a5,0x5
    1088:	b9478793          	addi	a5,a5,-1132 # 5c18 <_data>
    108c:	00005417          	auipc	s0,0x5
    1090:	b8c40413          	addi	s0,s0,-1140 # 5c18 <_data>
    1094:	00112623          	sw	ra,12(sp)
    1098:	00912223          	sw	s1,4(sp)
    109c:	40878933          	sub	s2,a5,s0
    10a0:	02878063          	beq	a5,s0,10c0 <__libc_init_array+0x48>
    10a4:	40295913          	srai	s2,s2,0x2
    10a8:	00000493          	li	s1,0
    10ac:	00042783          	lw	a5,0(s0)
    10b0:	00148493          	addi	s1,s1,1
    10b4:	00440413          	addi	s0,s0,4
    10b8:	000780e7          	jalr	a5
    10bc:	ff24e8e3          	bltu	s1,s2,10ac <__libc_init_array+0x34>
    10c0:	00005797          	auipc	a5,0x5
    10c4:	b5878793          	addi	a5,a5,-1192 # 5c18 <_data>
    10c8:	00005417          	auipc	s0,0x5
    10cc:	b5040413          	addi	s0,s0,-1200 # 5c18 <_data>
    10d0:	40878933          	sub	s2,a5,s0
    10d4:	40295913          	srai	s2,s2,0x2
    10d8:	00878e63          	beq	a5,s0,10f4 <__libc_init_array+0x7c>
    10dc:	00000493          	li	s1,0
    10e0:	00042783          	lw	a5,0(s0)
    10e4:	00148493          	addi	s1,s1,1
    10e8:	00440413          	addi	s0,s0,4
    10ec:	000780e7          	jalr	a5
    10f0:	ff24e8e3          	bltu	s1,s2,10e0 <__libc_init_array+0x68>
    10f4:	00c12083          	lw	ra,12(sp)
    10f8:	00812403          	lw	s0,8(sp)
    10fc:	00412483          	lw	s1,4(sp)
    1100:	00012903          	lw	s2,0(sp)
    1104:	01010113          	addi	sp,sp,16
    1108:	00008067          	ret

0000110c <stdio_exit_handler>:
    110c:	00006617          	auipc	a2,0x6
    1110:	e4c60613          	addi	a2,a2,-436 # 6f58 <__sglue>
    1114:	00001597          	auipc	a1,0x1
    1118:	f8058593          	addi	a1,a1,-128 # 2094 <_fclose_r>
    111c:	00006517          	auipc	a0,0x6
    1120:	cfc50513          	addi	a0,a0,-772 # 6e18 <_impure_data>
    1124:	4700006f          	j	1594 <_fwalk_sglue>

00001128 <cleanup_stdio>:
    1128:	00452583          	lw	a1,4(a0)
    112c:	ff010113          	addi	sp,sp,-16
    1130:	00812423          	sw	s0,8(sp)
    1134:	00112623          	sw	ra,12(sp)
    1138:	00006797          	auipc	a5,0x6
    113c:	2e078793          	addi	a5,a5,736 # 7418 <__sf>
    1140:	00050413          	mv	s0,a0
    1144:	00f58463          	beq	a1,a5,114c <cleanup_stdio+0x24>
    1148:	74d000ef          	jal	2094 <_fclose_r>
    114c:	00842583          	lw	a1,8(s0)
    1150:	92018793          	addi	a5,gp,-1760 # 7480 <__sf+0x68>
    1154:	00f58663          	beq	a1,a5,1160 <cleanup_stdio+0x38>
    1158:	00040513          	mv	a0,s0
    115c:	739000ef          	jal	2094 <_fclose_r>
    1160:	00c42583          	lw	a1,12(s0)
    1164:	98818793          	addi	a5,gp,-1656 # 74e8 <__sf+0xd0>
    1168:	00f58c63          	beq	a1,a5,1180 <cleanup_stdio+0x58>
    116c:	00040513          	mv	a0,s0
    1170:	00812403          	lw	s0,8(sp)
    1174:	00c12083          	lw	ra,12(sp)
    1178:	01010113          	addi	sp,sp,16
    117c:	7190006f          	j	2094 <_fclose_r>
    1180:	00c12083          	lw	ra,12(sp)
    1184:	00812403          	lw	s0,8(sp)
    1188:	01010113          	addi	sp,sp,16
    118c:	00008067          	ret

00001190 <__fp_lock>:
    1190:	0645a783          	lw	a5,100(a1)
    1194:	0017f793          	andi	a5,a5,1
    1198:	00079863          	bnez	a5,11a8 <__fp_lock+0x18>
    119c:	00c5d783          	lhu	a5,12(a1)
    11a0:	2007f793          	andi	a5,a5,512
    11a4:	00078663          	beqz	a5,11b0 <__fp_lock+0x20>
    11a8:	00000513          	li	a0,0
    11ac:	00008067          	ret
    11b0:	0585a503          	lw	a0,88(a1)
    11b4:	ff010113          	addi	sp,sp,-16
    11b8:	00112623          	sw	ra,12(sp)
    11bc:	60c000ef          	jal	17c8 <__retarget_lock_acquire_recursive>
    11c0:	00c12083          	lw	ra,12(sp)
    11c4:	00000513          	li	a0,0
    11c8:	01010113          	addi	sp,sp,16
    11cc:	00008067          	ret

000011d0 <__fp_unlock>:
    11d0:	0645a783          	lw	a5,100(a1)
    11d4:	0017f793          	andi	a5,a5,1
    11d8:	00079863          	bnez	a5,11e8 <__fp_unlock+0x18>
    11dc:	00c5d783          	lhu	a5,12(a1)
    11e0:	2007f793          	andi	a5,a5,512
    11e4:	00078663          	beqz	a5,11f0 <__fp_unlock+0x20>
    11e8:	00000513          	li	a0,0
    11ec:	00008067          	ret
    11f0:	0585a503          	lw	a0,88(a1)
    11f4:	ff010113          	addi	sp,sp,-16
    11f8:	00112623          	sw	ra,12(sp)
    11fc:	5e4000ef          	jal	17e0 <__retarget_lock_release_recursive>
    1200:	00c12083          	lw	ra,12(sp)
    1204:	00000513          	li	a0,0
    1208:	01010113          	addi	sp,sp,16
    120c:	00008067          	ret

00001210 <global_stdio_init.part.0>:
    1210:	fe010113          	addi	sp,sp,-32
    1214:	00000797          	auipc	a5,0x0
    1218:	ef878793          	addi	a5,a5,-264 # 110c <stdio_exit_handler>
    121c:	00112e23          	sw	ra,28(sp)
    1220:	00812c23          	sw	s0,24(sp)
    1224:	00912a23          	sw	s1,20(sp)
    1228:	00006417          	auipc	s0,0x6
    122c:	1f040413          	addi	s0,s0,496 # 7418 <__sf>
    1230:	01212823          	sw	s2,16(sp)
    1234:	01312623          	sw	s3,12(sp)
    1238:	01412423          	sw	s4,8(sp)
    123c:	00800613          	li	a2,8
    1240:	00000593          	li	a1,0
    1244:	84f1a823          	sw	a5,-1968(gp) # 73b0 <__stdio_exit_handler>
    1248:	91418513          	addi	a0,gp,-1772 # 7474 <__sf+0x5c>
    124c:	00400793          	li	a5,4
    1250:	00f42623          	sw	a5,12(s0)
    1254:	00042023          	sw	zero,0(s0)
    1258:	00042223          	sw	zero,4(s0)
    125c:	00042423          	sw	zero,8(s0)
    1260:	06042223          	sw	zero,100(s0)
    1264:	00042823          	sw	zero,16(s0)
    1268:	00042a23          	sw	zero,20(s0)
    126c:	00042c23          	sw	zero,24(s0)
    1270:	574000ef          	jal	17e4 <memset>
    1274:	00000a17          	auipc	s4,0x0
    1278:	3d4a0a13          	addi	s4,s4,980 # 1648 <__sread>
    127c:	00000997          	auipc	s3,0x0
    1280:	43098993          	addi	s3,s3,1072 # 16ac <__swrite>
    1284:	00000917          	auipc	s2,0x0
    1288:	4b090913          	addi	s2,s2,1200 # 1734 <__sseek>
    128c:	00000497          	auipc	s1,0x0
    1290:	52048493          	addi	s1,s1,1312 # 17ac <__sclose>
    1294:	91018513          	addi	a0,gp,-1776 # 7470 <__sf+0x58>
    1298:	03442023          	sw	s4,32(s0)
    129c:	03342223          	sw	s3,36(s0)
    12a0:	03242423          	sw	s2,40(s0)
    12a4:	02942623          	sw	s1,44(s0)
    12a8:	00842e23          	sw	s0,28(s0)
    12ac:	50c000ef          	jal	17b8 <__retarget_lock_init_recursive>
    12b0:	000107b7          	lui	a5,0x10
    12b4:	00978793          	addi	a5,a5,9 # 10009 <__freertos_irq_stack_top+0x7a89>
    12b8:	00800613          	li	a2,8
    12bc:	00000593          	li	a1,0
    12c0:	97c18513          	addi	a0,gp,-1668 # 74dc <__sf+0xc4>
    12c4:	06f42a23          	sw	a5,116(s0)
    12c8:	06042423          	sw	zero,104(s0)
    12cc:	06042623          	sw	zero,108(s0)
    12d0:	06042823          	sw	zero,112(s0)
    12d4:	0c042623          	sw	zero,204(s0)
    12d8:	06042c23          	sw	zero,120(s0)
    12dc:	06042e23          	sw	zero,124(s0)
    12e0:	08042023          	sw	zero,128(s0)
    12e4:	500000ef          	jal	17e4 <memset>
    12e8:	92018793          	addi	a5,gp,-1760 # 7480 <__sf+0x68>
    12ec:	97818513          	addi	a0,gp,-1672 # 74d8 <__sf+0xc0>
    12f0:	08f42223          	sw	a5,132(s0)
    12f4:	09442423          	sw	s4,136(s0)
    12f8:	09342623          	sw	s3,140(s0)
    12fc:	09242823          	sw	s2,144(s0)
    1300:	08942a23          	sw	s1,148(s0)
    1304:	4b4000ef          	jal	17b8 <__retarget_lock_init_recursive>
    1308:	000207b7          	lui	a5,0x20
    130c:	01278793          	addi	a5,a5,18 # 20012 <__freertos_irq_stack_top+0x17a92>
    1310:	00800613          	li	a2,8
    1314:	00000593          	li	a1,0
    1318:	9e418513          	addi	a0,gp,-1564 # 7544 <__sf+0x12c>
    131c:	0cf42e23          	sw	a5,220(s0)
    1320:	0c042823          	sw	zero,208(s0)
    1324:	0c042a23          	sw	zero,212(s0)
    1328:	0c042c23          	sw	zero,216(s0)
    132c:	12042a23          	sw	zero,308(s0)
    1330:	0e042023          	sw	zero,224(s0)
    1334:	0e042223          	sw	zero,228(s0)
    1338:	0e042423          	sw	zero,232(s0)
    133c:	4a8000ef          	jal	17e4 <memset>
    1340:	98818793          	addi	a5,gp,-1656 # 74e8 <__sf+0xd0>
    1344:	0f442823          	sw	s4,240(s0)
    1348:	0f342a23          	sw	s3,244(s0)
    134c:	0f242c23          	sw	s2,248(s0)
    1350:	0e942e23          	sw	s1,252(s0)
    1354:	0ef42623          	sw	a5,236(s0)
    1358:	01812403          	lw	s0,24(sp)
    135c:	01c12083          	lw	ra,28(sp)
    1360:	01412483          	lw	s1,20(sp)
    1364:	01012903          	lw	s2,16(sp)
    1368:	00c12983          	lw	s3,12(sp)
    136c:	00812a03          	lw	s4,8(sp)
    1370:	9e018513          	addi	a0,gp,-1568 # 7540 <__sf+0x128>
    1374:	02010113          	addi	sp,sp,32
    1378:	4400006f          	j	17b8 <__retarget_lock_init_recursive>

0000137c <__sfp>:
    137c:	fe010113          	addi	sp,sp,-32
    1380:	01312623          	sw	s3,12(sp)
    1384:	00050993          	mv	s3,a0
    1388:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    138c:	00112e23          	sw	ra,28(sp)
    1390:	00812c23          	sw	s0,24(sp)
    1394:	00912a23          	sw	s1,20(sp)
    1398:	01212823          	sw	s2,16(sp)
    139c:	42c000ef          	jal	17c8 <__retarget_lock_acquire_recursive>
    13a0:	8501a783          	lw	a5,-1968(gp) # 73b0 <__stdio_exit_handler>
    13a4:	10078063          	beqz	a5,14a4 <__sfp+0x128>
    13a8:	00006917          	auipc	s2,0x6
    13ac:	bb090913          	addi	s2,s2,-1104 # 6f58 <__sglue>
    13b0:	fff00493          	li	s1,-1
    13b4:	00492783          	lw	a5,4(s2)
    13b8:	00892403          	lw	s0,8(s2)
    13bc:	fff78793          	addi	a5,a5,-1
    13c0:	0007d863          	bgez	a5,13d0 <__sfp+0x54>
    13c4:	0900006f          	j	1454 <__sfp+0xd8>
    13c8:	06840413          	addi	s0,s0,104
    13cc:	08978463          	beq	a5,s1,1454 <__sfp+0xd8>
    13d0:	00c41703          	lh	a4,12(s0)
    13d4:	fff78793          	addi	a5,a5,-1
    13d8:	fe0718e3          	bnez	a4,13c8 <__sfp+0x4c>
    13dc:	ffff07b7          	lui	a5,0xffff0
    13e0:	00178793          	addi	a5,a5,1 # ffff0001 <__freertos_irq_stack_top+0xfffe7a81>
    13e4:	00f42623          	sw	a5,12(s0)
    13e8:	05840513          	addi	a0,s0,88
    13ec:	06042223          	sw	zero,100(s0)
    13f0:	3c8000ef          	jal	17b8 <__retarget_lock_init_recursive>
    13f4:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    13f8:	3e8000ef          	jal	17e0 <__retarget_lock_release_recursive>
    13fc:	00800613          	li	a2,8
    1400:	00042023          	sw	zero,0(s0)
    1404:	00042423          	sw	zero,8(s0)
    1408:	00042223          	sw	zero,4(s0)
    140c:	00042823          	sw	zero,16(s0)
    1410:	00042a23          	sw	zero,20(s0)
    1414:	00042c23          	sw	zero,24(s0)
    1418:	00000593          	li	a1,0
    141c:	05c40513          	addi	a0,s0,92
    1420:	3c4000ef          	jal	17e4 <memset>
    1424:	02042823          	sw	zero,48(s0)
    1428:	02042a23          	sw	zero,52(s0)
    142c:	04042223          	sw	zero,68(s0)
    1430:	04042423          	sw	zero,72(s0)
    1434:	01c12083          	lw	ra,28(sp)
    1438:	00040513          	mv	a0,s0
    143c:	01812403          	lw	s0,24(sp)
    1440:	01412483          	lw	s1,20(sp)
    1444:	01012903          	lw	s2,16(sp)
    1448:	00c12983          	lw	s3,12(sp)
    144c:	02010113          	addi	sp,sp,32
    1450:	00008067          	ret
    1454:	00092403          	lw	s0,0(s2)
    1458:	00040663          	beqz	s0,1464 <__sfp+0xe8>
    145c:	00040913          	mv	s2,s0
    1460:	f55ff06f          	j	13b4 <__sfp+0x38>
    1464:	1ac00593          	li	a1,428
    1468:	00098513          	mv	a0,s3
    146c:	454000ef          	jal	18c0 <_malloc_r>
    1470:	00050413          	mv	s0,a0
    1474:	02050c63          	beqz	a0,14ac <__sfp+0x130>
    1478:	00c50513          	addi	a0,a0,12
    147c:	00400793          	li	a5,4
    1480:	00042023          	sw	zero,0(s0)
    1484:	00f42223          	sw	a5,4(s0)
    1488:	00a42423          	sw	a0,8(s0)
    148c:	1a000613          	li	a2,416
    1490:	00000593          	li	a1,0
    1494:	350000ef          	jal	17e4 <memset>
    1498:	00892023          	sw	s0,0(s2)
    149c:	00040913          	mv	s2,s0
    14a0:	f15ff06f          	j	13b4 <__sfp+0x38>
    14a4:	d6dff0ef          	jal	1210 <global_stdio_init.part.0>
    14a8:	f01ff06f          	j	13a8 <__sfp+0x2c>
    14ac:	00092023          	sw	zero,0(s2)
    14b0:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    14b4:	32c000ef          	jal	17e0 <__retarget_lock_release_recursive>
    14b8:	00c00793          	li	a5,12
    14bc:	00f9a023          	sw	a5,0(s3)
    14c0:	f75ff06f          	j	1434 <__sfp+0xb8>

000014c4 <__sinit>:
    14c4:	ff010113          	addi	sp,sp,-16
    14c8:	00812423          	sw	s0,8(sp)
    14cc:	00050413          	mv	s0,a0
    14d0:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    14d4:	00112623          	sw	ra,12(sp)
    14d8:	2f0000ef          	jal	17c8 <__retarget_lock_acquire_recursive>
    14dc:	03442783          	lw	a5,52(s0)
    14e0:	00079c63          	bnez	a5,14f8 <__sinit+0x34>
    14e4:	00000797          	auipc	a5,0x0
    14e8:	c4478793          	addi	a5,a5,-956 # 1128 <cleanup_stdio>
    14ec:	02f42a23          	sw	a5,52(s0)
    14f0:	8501a783          	lw	a5,-1968(gp) # 73b0 <__stdio_exit_handler>
    14f4:	00078c63          	beqz	a5,150c <__sinit+0x48>
    14f8:	00812403          	lw	s0,8(sp)
    14fc:	00c12083          	lw	ra,12(sp)
    1500:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    1504:	01010113          	addi	sp,sp,16
    1508:	2d80006f          	j	17e0 <__retarget_lock_release_recursive>
    150c:	d05ff0ef          	jal	1210 <global_stdio_init.part.0>
    1510:	00812403          	lw	s0,8(sp)
    1514:	00c12083          	lw	ra,12(sp)
    1518:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    151c:	01010113          	addi	sp,sp,16
    1520:	2c00006f          	j	17e0 <__retarget_lock_release_recursive>

00001524 <__sfp_lock_acquire>:
    1524:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    1528:	2a00006f          	j	17c8 <__retarget_lock_acquire_recursive>

0000152c <__sfp_lock_release>:
    152c:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    1530:	2b00006f          	j	17e0 <__retarget_lock_release_recursive>

00001534 <__fp_lock_all>:
    1534:	ff010113          	addi	sp,sp,-16
    1538:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    153c:	00112623          	sw	ra,12(sp)
    1540:	288000ef          	jal	17c8 <__retarget_lock_acquire_recursive>
    1544:	00c12083          	lw	ra,12(sp)
    1548:	00006617          	auipc	a2,0x6
    154c:	a1060613          	addi	a2,a2,-1520 # 6f58 <__sglue>
    1550:	00000597          	auipc	a1,0x0
    1554:	c4058593          	addi	a1,a1,-960 # 1190 <__fp_lock>
    1558:	00000513          	li	a0,0
    155c:	01010113          	addi	sp,sp,16
    1560:	0340006f          	j	1594 <_fwalk_sglue>

00001564 <__fp_unlock_all>:
    1564:	ff010113          	addi	sp,sp,-16
    1568:	00006617          	auipc	a2,0x6
    156c:	9f060613          	addi	a2,a2,-1552 # 6f58 <__sglue>
    1570:	00000597          	auipc	a1,0x0
    1574:	c6058593          	addi	a1,a1,-928 # 11d0 <__fp_unlock>
    1578:	00000513          	li	a0,0
    157c:	00112623          	sw	ra,12(sp)
    1580:	014000ef          	jal	1594 <_fwalk_sglue>
    1584:	00c12083          	lw	ra,12(sp)
    1588:	87018513          	addi	a0,gp,-1936 # 73d0 <__lock___sfp_recursive_mutex>
    158c:	01010113          	addi	sp,sp,16
    1590:	2500006f          	j	17e0 <__retarget_lock_release_recursive>

00001594 <_fwalk_sglue>:
    1594:	fd010113          	addi	sp,sp,-48
    1598:	03212023          	sw	s2,32(sp)
    159c:	01312e23          	sw	s3,28(sp)
    15a0:	01412c23          	sw	s4,24(sp)
    15a4:	01512a23          	sw	s5,20(sp)
    15a8:	01612823          	sw	s6,16(sp)
    15ac:	01712623          	sw	s7,12(sp)
    15b0:	02112623          	sw	ra,44(sp)
    15b4:	02812423          	sw	s0,40(sp)
    15b8:	02912223          	sw	s1,36(sp)
    15bc:	00050b13          	mv	s6,a0
    15c0:	00058b93          	mv	s7,a1
    15c4:	00060a93          	mv	s5,a2
    15c8:	00000a13          	li	s4,0
    15cc:	00100993          	li	s3,1
    15d0:	fff00913          	li	s2,-1
    15d4:	004aa483          	lw	s1,4(s5)
    15d8:	008aa403          	lw	s0,8(s5)
    15dc:	fff48493          	addi	s1,s1,-1
    15e0:	0204c863          	bltz	s1,1610 <_fwalk_sglue+0x7c>
    15e4:	00c45783          	lhu	a5,12(s0)
    15e8:	00f9fe63          	bgeu	s3,a5,1604 <_fwalk_sglue+0x70>
    15ec:	00e41783          	lh	a5,14(s0)
    15f0:	00040593          	mv	a1,s0
    15f4:	000b0513          	mv	a0,s6
    15f8:	01278663          	beq	a5,s2,1604 <_fwalk_sglue+0x70>
    15fc:	000b80e7          	jalr	s7
    1600:	00aa6a33          	or	s4,s4,a0
    1604:	fff48493          	addi	s1,s1,-1
    1608:	06840413          	addi	s0,s0,104
    160c:	fd249ce3          	bne	s1,s2,15e4 <_fwalk_sglue+0x50>
    1610:	000aaa83          	lw	s5,0(s5)
    1614:	fc0a90e3          	bnez	s5,15d4 <_fwalk_sglue+0x40>
    1618:	02c12083          	lw	ra,44(sp)
    161c:	02812403          	lw	s0,40(sp)
    1620:	02412483          	lw	s1,36(sp)
    1624:	02012903          	lw	s2,32(sp)
    1628:	01c12983          	lw	s3,28(sp)
    162c:	01412a83          	lw	s5,20(sp)
    1630:	01012b03          	lw	s6,16(sp)
    1634:	00c12b83          	lw	s7,12(sp)
    1638:	000a0513          	mv	a0,s4
    163c:	01812a03          	lw	s4,24(sp)
    1640:	03010113          	addi	sp,sp,48
    1644:	00008067          	ret

00001648 <__sread>:
    1648:	ff010113          	addi	sp,sp,-16
    164c:	00812423          	sw	s0,8(sp)
    1650:	00058413          	mv	s0,a1
    1654:	00e59583          	lh	a1,14(a1)
    1658:	00112623          	sw	ra,12(sp)
    165c:	54c020ef          	jal	3ba8 <_read_r>
    1660:	02054063          	bltz	a0,1680 <__sread+0x38>
    1664:	05042783          	lw	a5,80(s0)
    1668:	00c12083          	lw	ra,12(sp)
    166c:	00a787b3          	add	a5,a5,a0
    1670:	04f42823          	sw	a5,80(s0)
    1674:	00812403          	lw	s0,8(sp)
    1678:	01010113          	addi	sp,sp,16
    167c:	00008067          	ret
    1680:	00c45783          	lhu	a5,12(s0)
    1684:	fffff737          	lui	a4,0xfffff
    1688:	fff70713          	addi	a4,a4,-1 # ffffefff <__freertos_irq_stack_top+0xffff6a7f>
    168c:	00e7f7b3          	and	a5,a5,a4
    1690:	00c12083          	lw	ra,12(sp)
    1694:	00f41623          	sh	a5,12(s0)
    1698:	00812403          	lw	s0,8(sp)
    169c:	01010113          	addi	sp,sp,16
    16a0:	00008067          	ret

000016a4 <__seofread>:
    16a4:	00000513          	li	a0,0
    16a8:	00008067          	ret

000016ac <__swrite>:
    16ac:	00c59783          	lh	a5,12(a1)
    16b0:	fe010113          	addi	sp,sp,-32
    16b4:	00812c23          	sw	s0,24(sp)
    16b8:	00912a23          	sw	s1,20(sp)
    16bc:	01212823          	sw	s2,16(sp)
    16c0:	01312623          	sw	s3,12(sp)
    16c4:	00112e23          	sw	ra,28(sp)
    16c8:	1007f713          	andi	a4,a5,256
    16cc:	00058413          	mv	s0,a1
    16d0:	00050493          	mv	s1,a0
    16d4:	00060913          	mv	s2,a2
    16d8:	00068993          	mv	s3,a3
    16dc:	04071063          	bnez	a4,171c <__swrite+0x70>
    16e0:	fffff737          	lui	a4,0xfffff
    16e4:	fff70713          	addi	a4,a4,-1 # ffffefff <__freertos_irq_stack_top+0xffff6a7f>
    16e8:	00e7f7b3          	and	a5,a5,a4
    16ec:	00e41583          	lh	a1,14(s0)
    16f0:	00f41623          	sh	a5,12(s0)
    16f4:	01812403          	lw	s0,24(sp)
    16f8:	01c12083          	lw	ra,28(sp)
    16fc:	00098693          	mv	a3,s3
    1700:	00090613          	mv	a2,s2
    1704:	00c12983          	lw	s3,12(sp)
    1708:	01012903          	lw	s2,16(sp)
    170c:	00048513          	mv	a0,s1
    1710:	01412483          	lw	s1,20(sp)
    1714:	02010113          	addi	sp,sp,32
    1718:	4980206f          	j	3bb0 <_write_r>
    171c:	00e59583          	lh	a1,14(a1)
    1720:	00200693          	li	a3,2
    1724:	00000613          	li	a2,0
    1728:	478020ef          	jal	3ba0 <_lseek_r>
    172c:	00c41783          	lh	a5,12(s0)
    1730:	fb1ff06f          	j	16e0 <__swrite+0x34>

00001734 <__sseek>:
    1734:	ff010113          	addi	sp,sp,-16
    1738:	00812423          	sw	s0,8(sp)
    173c:	00058413          	mv	s0,a1
    1740:	00e59583          	lh	a1,14(a1)
    1744:	00112623          	sw	ra,12(sp)
    1748:	458020ef          	jal	3ba0 <_lseek_r>
    174c:	fff00793          	li	a5,-1
    1750:	02f50863          	beq	a0,a5,1780 <__sseek+0x4c>
    1754:	00c45783          	lhu	a5,12(s0)
    1758:	00001737          	lui	a4,0x1
    175c:	00c12083          	lw	ra,12(sp)
    1760:	00e7e7b3          	or	a5,a5,a4
    1764:	01079793          	slli	a5,a5,0x10
    1768:	4107d793          	srai	a5,a5,0x10
    176c:	04a42823          	sw	a0,80(s0)
    1770:	00f41623          	sh	a5,12(s0)
    1774:	00812403          	lw	s0,8(sp)
    1778:	01010113          	addi	sp,sp,16
    177c:	00008067          	ret
    1780:	00c45783          	lhu	a5,12(s0)
    1784:	fffff737          	lui	a4,0xfffff
    1788:	fff70713          	addi	a4,a4,-1 # ffffefff <__freertos_irq_stack_top+0xffff6a7f>
    178c:	00e7f7b3          	and	a5,a5,a4
    1790:	01079793          	slli	a5,a5,0x10
    1794:	4107d793          	srai	a5,a5,0x10
    1798:	00c12083          	lw	ra,12(sp)
    179c:	00f41623          	sh	a5,12(s0)
    17a0:	00812403          	lw	s0,8(sp)
    17a4:	01010113          	addi	sp,sp,16
    17a8:	00008067          	ret

000017ac <__sclose>:
    17ac:	00e59583          	lh	a1,14(a1)
    17b0:	3e80206f          	j	3b98 <_close_r>

000017b4 <__retarget_lock_init>:
    17b4:	00008067          	ret

000017b8 <__retarget_lock_init_recursive>:
    17b8:	00008067          	ret

000017bc <__retarget_lock_close>:
    17bc:	00008067          	ret

000017c0 <__retarget_lock_close_recursive>:
    17c0:	00008067          	ret

000017c4 <__retarget_lock_acquire>:
    17c4:	00008067          	ret

000017c8 <__retarget_lock_acquire_recursive>:
    17c8:	00008067          	ret

000017cc <__retarget_lock_try_acquire>:
    17cc:	00100513          	li	a0,1
    17d0:	00008067          	ret

000017d4 <__retarget_lock_try_acquire_recursive>:
    17d4:	00100513          	li	a0,1
    17d8:	00008067          	ret

000017dc <__retarget_lock_release>:
    17dc:	00008067          	ret

000017e0 <__retarget_lock_release_recursive>:
    17e0:	00008067          	ret

000017e4 <memset>:
    17e4:	00f00313          	li	t1,15
    17e8:	00050713          	mv	a4,a0
    17ec:	02c37e63          	bgeu	t1,a2,1828 <memset+0x44>
    17f0:	00f77793          	andi	a5,a4,15
    17f4:	0a079063          	bnez	a5,1894 <memset+0xb0>
    17f8:	08059263          	bnez	a1,187c <memset+0x98>
    17fc:	ff067693          	andi	a3,a2,-16
    1800:	00f67613          	andi	a2,a2,15
    1804:	00e686b3          	add	a3,a3,a4
    1808:	00b72023          	sw	a1,0(a4)
    180c:	00b72223          	sw	a1,4(a4)
    1810:	00b72423          	sw	a1,8(a4)
    1814:	00b72623          	sw	a1,12(a4)
    1818:	01070713          	addi	a4,a4,16
    181c:	fed766e3          	bltu	a4,a3,1808 <memset+0x24>
    1820:	00061463          	bnez	a2,1828 <memset+0x44>
    1824:	00008067          	ret
    1828:	40c306b3          	sub	a3,t1,a2
    182c:	00269693          	slli	a3,a3,0x2
    1830:	00000297          	auipc	t0,0x0
    1834:	005686b3          	add	a3,a3,t0
    1838:	00c68067          	jr	12(a3)
    183c:	00b70723          	sb	a1,14(a4)
    1840:	00b706a3          	sb	a1,13(a4)
    1844:	00b70623          	sb	a1,12(a4)
    1848:	00b705a3          	sb	a1,11(a4)
    184c:	00b70523          	sb	a1,10(a4)
    1850:	00b704a3          	sb	a1,9(a4)
    1854:	00b70423          	sb	a1,8(a4)
    1858:	00b703a3          	sb	a1,7(a4)
    185c:	00b70323          	sb	a1,6(a4)
    1860:	00b702a3          	sb	a1,5(a4)
    1864:	00b70223          	sb	a1,4(a4)
    1868:	00b701a3          	sb	a1,3(a4)
    186c:	00b70123          	sb	a1,2(a4)
    1870:	00b700a3          	sb	a1,1(a4)
    1874:	00b70023          	sb	a1,0(a4)
    1878:	00008067          	ret
    187c:	0ff5f593          	zext.b	a1,a1
    1880:	00859693          	slli	a3,a1,0x8
    1884:	00d5e5b3          	or	a1,a1,a3
    1888:	01059693          	slli	a3,a1,0x10
    188c:	00d5e5b3          	or	a1,a1,a3
    1890:	f6dff06f          	j	17fc <memset+0x18>
    1894:	00279693          	slli	a3,a5,0x2
    1898:	00000297          	auipc	t0,0x0
    189c:	005686b3          	add	a3,a3,t0
    18a0:	00008293          	mv	t0,ra
    18a4:	fa0680e7          	jalr	-96(a3)
    18a8:	00028093          	mv	ra,t0
    18ac:	ff078793          	addi	a5,a5,-16
    18b0:	40f70733          	sub	a4,a4,a5
    18b4:	00f60633          	add	a2,a2,a5
    18b8:	f6c378e3          	bgeu	t1,a2,1828 <memset+0x44>
    18bc:	f3dff06f          	j	17f8 <memset+0x14>

000018c0 <_malloc_r>:
    18c0:	fd010113          	addi	sp,sp,-48
    18c4:	03212023          	sw	s2,32(sp)
    18c8:	02112623          	sw	ra,44(sp)
    18cc:	02812423          	sw	s0,40(sp)
    18d0:	02912223          	sw	s1,36(sp)
    18d4:	01312e23          	sw	s3,28(sp)
    18d8:	00b58793          	addi	a5,a1,11
    18dc:	01600713          	li	a4,22
    18e0:	00050913          	mv	s2,a0
    18e4:	08f76263          	bltu	a4,a5,1968 <_malloc_r+0xa8>
    18e8:	01000793          	li	a5,16
    18ec:	20b7e663          	bltu	a5,a1,1af8 <_malloc_r+0x238>
    18f0:	794000ef          	jal	2084 <__malloc_lock>
    18f4:	01800793          	li	a5,24
    18f8:	00200593          	li	a1,2
    18fc:	01000493          	li	s1,16
    1900:	00005997          	auipc	s3,0x5
    1904:	66498993          	addi	s3,s3,1636 # 6f64 <__malloc_av_>
    1908:	00f987b3          	add	a5,s3,a5
    190c:	0047a403          	lw	s0,4(a5)
    1910:	ff878713          	addi	a4,a5,-8
    1914:	34e40863          	beq	s0,a4,1c64 <_malloc_r+0x3a4>
    1918:	00442783          	lw	a5,4(s0)
    191c:	00c42683          	lw	a3,12(s0)
    1920:	00842603          	lw	a2,8(s0)
    1924:	ffc7f793          	andi	a5,a5,-4
    1928:	00f407b3          	add	a5,s0,a5
    192c:	0047a703          	lw	a4,4(a5)
    1930:	00d62623          	sw	a3,12(a2)
    1934:	00c6a423          	sw	a2,8(a3)
    1938:	00176713          	ori	a4,a4,1
    193c:	00090513          	mv	a0,s2
    1940:	00e7a223          	sw	a4,4(a5)
    1944:	748000ef          	jal	208c <__malloc_unlock>
    1948:	00840513          	addi	a0,s0,8
    194c:	02c12083          	lw	ra,44(sp)
    1950:	02812403          	lw	s0,40(sp)
    1954:	02412483          	lw	s1,36(sp)
    1958:	02012903          	lw	s2,32(sp)
    195c:	01c12983          	lw	s3,28(sp)
    1960:	03010113          	addi	sp,sp,48
    1964:	00008067          	ret
    1968:	ff87f493          	andi	s1,a5,-8
    196c:	1807c663          	bltz	a5,1af8 <_malloc_r+0x238>
    1970:	18b4e463          	bltu	s1,a1,1af8 <_malloc_r+0x238>
    1974:	710000ef          	jal	2084 <__malloc_lock>
    1978:	1f700793          	li	a5,503
    197c:	3e97fe63          	bgeu	a5,s1,1d78 <_malloc_r+0x4b8>
    1980:	0094d793          	srli	a5,s1,0x9
    1984:	18078263          	beqz	a5,1b08 <_malloc_r+0x248>
    1988:	00400713          	li	a4,4
    198c:	34f76463          	bltu	a4,a5,1cd4 <_malloc_r+0x414>
    1990:	0064d793          	srli	a5,s1,0x6
    1994:	03978593          	addi	a1,a5,57
    1998:	03878813          	addi	a6,a5,56
    199c:	00359613          	slli	a2,a1,0x3
    19a0:	00005997          	auipc	s3,0x5
    19a4:	5c498993          	addi	s3,s3,1476 # 6f64 <__malloc_av_>
    19a8:	00c98633          	add	a2,s3,a2
    19ac:	00462403          	lw	s0,4(a2)
    19b0:	ff860613          	addi	a2,a2,-8
    19b4:	02860863          	beq	a2,s0,19e4 <_malloc_r+0x124>
    19b8:	00f00513          	li	a0,15
    19bc:	0140006f          	j	19d0 <_malloc_r+0x110>
    19c0:	00c42683          	lw	a3,12(s0)
    19c4:	28075c63          	bgez	a4,1c5c <_malloc_r+0x39c>
    19c8:	00d60e63          	beq	a2,a3,19e4 <_malloc_r+0x124>
    19cc:	00068413          	mv	s0,a3
    19d0:	00442783          	lw	a5,4(s0)
    19d4:	ffc7f793          	andi	a5,a5,-4
    19d8:	40978733          	sub	a4,a5,s1
    19dc:	fee552e3          	bge	a0,a4,19c0 <_malloc_r+0x100>
    19e0:	00080593          	mv	a1,a6
    19e4:	0109a403          	lw	s0,16(s3)
    19e8:	00005897          	auipc	a7,0x5
    19ec:	58488893          	addi	a7,a7,1412 # 6f6c <__malloc_av_+0x8>
    19f0:	27140263          	beq	s0,a7,1c54 <_malloc_r+0x394>
    19f4:	00442783          	lw	a5,4(s0)
    19f8:	00f00693          	li	a3,15
    19fc:	ffc7f793          	andi	a5,a5,-4
    1a00:	40978733          	sub	a4,a5,s1
    1a04:	38e6c063          	blt	a3,a4,1d84 <_malloc_r+0x4c4>
    1a08:	0119aa23          	sw	a7,20(s3)
    1a0c:	0119a823          	sw	a7,16(s3)
    1a10:	34075463          	bgez	a4,1d58 <_malloc_r+0x498>
    1a14:	1ff00713          	li	a4,511
    1a18:	0049a503          	lw	a0,4(s3)
    1a1c:	24f76c63          	bltu	a4,a5,1c74 <_malloc_r+0x3b4>
    1a20:	ff87f713          	andi	a4,a5,-8
    1a24:	00870713          	addi	a4,a4,8
    1a28:	00e98733          	add	a4,s3,a4
    1a2c:	00072683          	lw	a3,0(a4)
    1a30:	0057d613          	srli	a2,a5,0x5
    1a34:	00100793          	li	a5,1
    1a38:	00c797b3          	sll	a5,a5,a2
    1a3c:	00f56533          	or	a0,a0,a5
    1a40:	ff870793          	addi	a5,a4,-8
    1a44:	00f42623          	sw	a5,12(s0)
    1a48:	00d42423          	sw	a3,8(s0)
    1a4c:	00a9a223          	sw	a0,4(s3)
    1a50:	00872023          	sw	s0,0(a4)
    1a54:	0086a623          	sw	s0,12(a3)
    1a58:	4025d793          	srai	a5,a1,0x2
    1a5c:	00100613          	li	a2,1
    1a60:	00f61633          	sll	a2,a2,a5
    1a64:	0ac56a63          	bltu	a0,a2,1b18 <_malloc_r+0x258>
    1a68:	00a677b3          	and	a5,a2,a0
    1a6c:	02079463          	bnez	a5,1a94 <_malloc_r+0x1d4>
    1a70:	00161613          	slli	a2,a2,0x1
    1a74:	ffc5f593          	andi	a1,a1,-4
    1a78:	00a677b3          	and	a5,a2,a0
    1a7c:	00458593          	addi	a1,a1,4
    1a80:	00079a63          	bnez	a5,1a94 <_malloc_r+0x1d4>
    1a84:	00161613          	slli	a2,a2,0x1
    1a88:	00a677b3          	and	a5,a2,a0
    1a8c:	00458593          	addi	a1,a1,4
    1a90:	fe078ae3          	beqz	a5,1a84 <_malloc_r+0x1c4>
    1a94:	00f00813          	li	a6,15
    1a98:	00359313          	slli	t1,a1,0x3
    1a9c:	00698333          	add	t1,s3,t1
    1aa0:	00030513          	mv	a0,t1
    1aa4:	00c52783          	lw	a5,12(a0)
    1aa8:	00058e13          	mv	t3,a1
    1aac:	24f50663          	beq	a0,a5,1cf8 <_malloc_r+0x438>
    1ab0:	0047a703          	lw	a4,4(a5)
    1ab4:	00078413          	mv	s0,a5
    1ab8:	00c7a783          	lw	a5,12(a5)
    1abc:	ffc77713          	andi	a4,a4,-4
    1ac0:	409706b3          	sub	a3,a4,s1
    1ac4:	24d84663          	blt	a6,a3,1d10 <_malloc_r+0x450>
    1ac8:	fe06c2e3          	bltz	a3,1aac <_malloc_r+0x1ec>
    1acc:	00e40733          	add	a4,s0,a4
    1ad0:	00472683          	lw	a3,4(a4)
    1ad4:	00842603          	lw	a2,8(s0)
    1ad8:	00090513          	mv	a0,s2
    1adc:	0016e693          	ori	a3,a3,1
    1ae0:	00d72223          	sw	a3,4(a4)
    1ae4:	00f62623          	sw	a5,12(a2)
    1ae8:	00c7a423          	sw	a2,8(a5)
    1aec:	5a0000ef          	jal	208c <__malloc_unlock>
    1af0:	00840513          	addi	a0,s0,8
    1af4:	e59ff06f          	j	194c <_malloc_r+0x8c>
    1af8:	00c00793          	li	a5,12
    1afc:	00f92023          	sw	a5,0(s2)
    1b00:	00000513          	li	a0,0
    1b04:	e49ff06f          	j	194c <_malloc_r+0x8c>
    1b08:	20000613          	li	a2,512
    1b0c:	04000593          	li	a1,64
    1b10:	03f00813          	li	a6,63
    1b14:	e8dff06f          	j	19a0 <_malloc_r+0xe0>
    1b18:	0089a403          	lw	s0,8(s3)
    1b1c:	01612823          	sw	s6,16(sp)
    1b20:	00442783          	lw	a5,4(s0)
    1b24:	ffc7fb13          	andi	s6,a5,-4
    1b28:	009b6863          	bltu	s6,s1,1b38 <_malloc_r+0x278>
    1b2c:	409b0733          	sub	a4,s6,s1
    1b30:	00f00793          	li	a5,15
    1b34:	0ce7ce63          	blt	a5,a4,1c10 <_malloc_r+0x350>
    1b38:	01912223          	sw	s9,4(sp)
    1b3c:	82018c93          	addi	s9,gp,-2016 # 7380 <__malloc_sbrk_base>
    1b40:	000ca703          	lw	a4,0(s9)
    1b44:	01412c23          	sw	s4,24(sp)
    1b48:	01512a23          	sw	s5,20(sp)
    1b4c:	87c1aa03          	lw	s4,-1924(gp) # 73dc <__malloc_top_pad>
    1b50:	01712623          	sw	s7,12(sp)
    1b54:	fff00793          	li	a5,-1
    1b58:	01640ab3          	add	s5,s0,s6
    1b5c:	01448a33          	add	s4,s1,s4
    1b60:	3cf70863          	beq	a4,a5,1f30 <_malloc_r+0x670>
    1b64:	000017b7          	lui	a5,0x1
    1b68:	00f78793          	addi	a5,a5,15 # 100f <init+0x7>
    1b6c:	00fa0a33          	add	s4,s4,a5
    1b70:	fffff7b7          	lui	a5,0xfffff
    1b74:	00fa7a33          	and	s4,s4,a5
    1b78:	000a0593          	mv	a1,s4
    1b7c:	00090513          	mv	a0,s2
    1b80:	28d000ef          	jal	260c <_sbrk_r>
    1b84:	fff00793          	li	a5,-1
    1b88:	00050b93          	mv	s7,a0
    1b8c:	44f50c63          	beq	a0,a5,1fe4 <_malloc_r+0x724>
    1b90:	01812423          	sw	s8,8(sp)
    1b94:	25556063          	bltu	a0,s5,1dd4 <_malloc_r+0x514>
    1b98:	9f018c13          	addi	s8,gp,-1552 # 7550 <__malloc_current_mallinfo>
    1b9c:	000c2703          	lw	a4,0(s8)
    1ba0:	00ea0733          	add	a4,s4,a4
    1ba4:	00ec2023          	sw	a4,0(s8)
    1ba8:	2aaa9a63          	bne	s5,a0,1e5c <_malloc_r+0x59c>
    1bac:	01451793          	slli	a5,a0,0x14
    1bb0:	2a079663          	bnez	a5,1e5c <_malloc_r+0x59c>
    1bb4:	0089ab83          	lw	s7,8(s3)
    1bb8:	014b07b3          	add	a5,s6,s4
    1bbc:	0017e793          	ori	a5,a5,1
    1bc0:	00fba223          	sw	a5,4(s7)
    1bc4:	87818693          	addi	a3,gp,-1928 # 73d8 <__malloc_max_sbrked_mem>
    1bc8:	0006a603          	lw	a2,0(a3)
    1bcc:	00e67463          	bgeu	a2,a4,1bd4 <_malloc_r+0x314>
    1bd0:	00e6a023          	sw	a4,0(a3)
    1bd4:	87418693          	addi	a3,gp,-1932 # 73d4 <__malloc_max_total_mem>
    1bd8:	0006a603          	lw	a2,0(a3)
    1bdc:	00e67463          	bgeu	a2,a4,1be4 <_malloc_r+0x324>
    1be0:	00e6a023          	sw	a4,0(a3)
    1be4:	00812c03          	lw	s8,8(sp)
    1be8:	000b8413          	mv	s0,s7
    1bec:	ffc7f793          	andi	a5,a5,-4
    1bf0:	40978733          	sub	a4,a5,s1
    1bf4:	3897ea63          	bltu	a5,s1,1f88 <_malloc_r+0x6c8>
    1bf8:	00f00793          	li	a5,15
    1bfc:	38e7d663          	bge	a5,a4,1f88 <_malloc_r+0x6c8>
    1c00:	01812a03          	lw	s4,24(sp)
    1c04:	01412a83          	lw	s5,20(sp)
    1c08:	00c12b83          	lw	s7,12(sp)
    1c0c:	00412c83          	lw	s9,4(sp)
    1c10:	0014e793          	ori	a5,s1,1
    1c14:	00f42223          	sw	a5,4(s0)
    1c18:	009404b3          	add	s1,s0,s1
    1c1c:	0099a423          	sw	s1,8(s3)
    1c20:	00176713          	ori	a4,a4,1
    1c24:	00090513          	mv	a0,s2
    1c28:	00e4a223          	sw	a4,4(s1)
    1c2c:	460000ef          	jal	208c <__malloc_unlock>
    1c30:	02c12083          	lw	ra,44(sp)
    1c34:	00840513          	addi	a0,s0,8
    1c38:	02812403          	lw	s0,40(sp)
    1c3c:	01012b03          	lw	s6,16(sp)
    1c40:	02412483          	lw	s1,36(sp)
    1c44:	02012903          	lw	s2,32(sp)
    1c48:	01c12983          	lw	s3,28(sp)
    1c4c:	03010113          	addi	sp,sp,48
    1c50:	00008067          	ret
    1c54:	0049a503          	lw	a0,4(s3)
    1c58:	e01ff06f          	j	1a58 <_malloc_r+0x198>
    1c5c:	00842603          	lw	a2,8(s0)
    1c60:	cc9ff06f          	j	1928 <_malloc_r+0x68>
    1c64:	00c7a403          	lw	s0,12(a5) # fffff00c <__freertos_irq_stack_top+0xffff6a8c>
    1c68:	00258593          	addi	a1,a1,2
    1c6c:	d6878ce3          	beq	a5,s0,19e4 <_malloc_r+0x124>
    1c70:	ca9ff06f          	j	1918 <_malloc_r+0x58>
    1c74:	0097d713          	srli	a4,a5,0x9
    1c78:	00400693          	li	a3,4
    1c7c:	14e6f263          	bgeu	a3,a4,1dc0 <_malloc_r+0x500>
    1c80:	01400693          	li	a3,20
    1c84:	32e6e463          	bltu	a3,a4,1fac <_malloc_r+0x6ec>
    1c88:	05c70613          	addi	a2,a4,92
    1c8c:	05b70693          	addi	a3,a4,91
    1c90:	00361613          	slli	a2,a2,0x3
    1c94:	00c98633          	add	a2,s3,a2
    1c98:	00062703          	lw	a4,0(a2)
    1c9c:	ff860613          	addi	a2,a2,-8
    1ca0:	00e61863          	bne	a2,a4,1cb0 <_malloc_r+0x3f0>
    1ca4:	2940006f          	j	1f38 <_malloc_r+0x678>
    1ca8:	00872703          	lw	a4,8(a4)
    1cac:	00e60863          	beq	a2,a4,1cbc <_malloc_r+0x3fc>
    1cb0:	00472683          	lw	a3,4(a4)
    1cb4:	ffc6f693          	andi	a3,a3,-4
    1cb8:	fed7e8e3          	bltu	a5,a3,1ca8 <_malloc_r+0x3e8>
    1cbc:	00c72603          	lw	a2,12(a4)
    1cc0:	00c42623          	sw	a2,12(s0)
    1cc4:	00e42423          	sw	a4,8(s0)
    1cc8:	00862423          	sw	s0,8(a2)
    1ccc:	00872623          	sw	s0,12(a4)
    1cd0:	d89ff06f          	j	1a58 <_malloc_r+0x198>
    1cd4:	01400713          	li	a4,20
    1cd8:	10f77863          	bgeu	a4,a5,1de8 <_malloc_r+0x528>
    1cdc:	05400713          	li	a4,84
    1ce0:	2ef76463          	bltu	a4,a5,1fc8 <_malloc_r+0x708>
    1ce4:	00c4d793          	srli	a5,s1,0xc
    1ce8:	06f78593          	addi	a1,a5,111
    1cec:	06e78813          	addi	a6,a5,110
    1cf0:	00359613          	slli	a2,a1,0x3
    1cf4:	cadff06f          	j	19a0 <_malloc_r+0xe0>
    1cf8:	001e0e13          	addi	t3,t3,1
    1cfc:	003e7793          	andi	a5,t3,3
    1d00:	00850513          	addi	a0,a0,8
    1d04:	10078063          	beqz	a5,1e04 <_malloc_r+0x544>
    1d08:	00c52783          	lw	a5,12(a0)
    1d0c:	da1ff06f          	j	1aac <_malloc_r+0x1ec>
    1d10:	00842603          	lw	a2,8(s0)
    1d14:	0014e593          	ori	a1,s1,1
    1d18:	00b42223          	sw	a1,4(s0)
    1d1c:	00f62623          	sw	a5,12(a2)
    1d20:	00c7a423          	sw	a2,8(a5)
    1d24:	009404b3          	add	s1,s0,s1
    1d28:	0099aa23          	sw	s1,20(s3)
    1d2c:	0099a823          	sw	s1,16(s3)
    1d30:	0016e793          	ori	a5,a3,1
    1d34:	0114a623          	sw	a7,12(s1)
    1d38:	0114a423          	sw	a7,8(s1)
    1d3c:	00f4a223          	sw	a5,4(s1)
    1d40:	00e40733          	add	a4,s0,a4
    1d44:	00090513          	mv	a0,s2
    1d48:	00d72023          	sw	a3,0(a4)
    1d4c:	340000ef          	jal	208c <__malloc_unlock>
    1d50:	00840513          	addi	a0,s0,8
    1d54:	bf9ff06f          	j	194c <_malloc_r+0x8c>
    1d58:	00f407b3          	add	a5,s0,a5
    1d5c:	0047a703          	lw	a4,4(a5)
    1d60:	00090513          	mv	a0,s2
    1d64:	00176713          	ori	a4,a4,1
    1d68:	00e7a223          	sw	a4,4(a5)
    1d6c:	320000ef          	jal	208c <__malloc_unlock>
    1d70:	00840513          	addi	a0,s0,8
    1d74:	bd9ff06f          	j	194c <_malloc_r+0x8c>
    1d78:	0034d593          	srli	a1,s1,0x3
    1d7c:	00848793          	addi	a5,s1,8
    1d80:	b81ff06f          	j	1900 <_malloc_r+0x40>
    1d84:	0014e693          	ori	a3,s1,1
    1d88:	00d42223          	sw	a3,4(s0)
    1d8c:	009404b3          	add	s1,s0,s1
    1d90:	0099aa23          	sw	s1,20(s3)
    1d94:	0099a823          	sw	s1,16(s3)
    1d98:	00176693          	ori	a3,a4,1
    1d9c:	0114a623          	sw	a7,12(s1)
    1da0:	0114a423          	sw	a7,8(s1)
    1da4:	00d4a223          	sw	a3,4(s1)
    1da8:	00f407b3          	add	a5,s0,a5
    1dac:	00090513          	mv	a0,s2
    1db0:	00e7a023          	sw	a4,0(a5)
    1db4:	2d8000ef          	jal	208c <__malloc_unlock>
    1db8:	00840513          	addi	a0,s0,8
    1dbc:	b91ff06f          	j	194c <_malloc_r+0x8c>
    1dc0:	0067d713          	srli	a4,a5,0x6
    1dc4:	03970613          	addi	a2,a4,57
    1dc8:	03870693          	addi	a3,a4,56
    1dcc:	00361613          	slli	a2,a2,0x3
    1dd0:	ec5ff06f          	j	1c94 <_malloc_r+0x3d4>
    1dd4:	07340c63          	beq	s0,s3,1e4c <_malloc_r+0x58c>
    1dd8:	0089a403          	lw	s0,8(s3)
    1ddc:	00812c03          	lw	s8,8(sp)
    1de0:	00442783          	lw	a5,4(s0)
    1de4:	e09ff06f          	j	1bec <_malloc_r+0x32c>
    1de8:	05c78593          	addi	a1,a5,92
    1dec:	05b78813          	addi	a6,a5,91
    1df0:	00359613          	slli	a2,a1,0x3
    1df4:	badff06f          	j	19a0 <_malloc_r+0xe0>
    1df8:	00832783          	lw	a5,8(t1)
    1dfc:	fff58593          	addi	a1,a1,-1
    1e00:	26679e63          	bne	a5,t1,207c <_malloc_r+0x7bc>
    1e04:	0035f793          	andi	a5,a1,3
    1e08:	ff830313          	addi	t1,t1,-8
    1e0c:	fe0796e3          	bnez	a5,1df8 <_malloc_r+0x538>
    1e10:	0049a703          	lw	a4,4(s3)
    1e14:	fff64793          	not	a5,a2
    1e18:	00e7f7b3          	and	a5,a5,a4
    1e1c:	00f9a223          	sw	a5,4(s3)
    1e20:	00161613          	slli	a2,a2,0x1
    1e24:	cec7eae3          	bltu	a5,a2,1b18 <_malloc_r+0x258>
    1e28:	ce0608e3          	beqz	a2,1b18 <_malloc_r+0x258>
    1e2c:	00f67733          	and	a4,a2,a5
    1e30:	00071a63          	bnez	a4,1e44 <_malloc_r+0x584>
    1e34:	00161613          	slli	a2,a2,0x1
    1e38:	00f67733          	and	a4,a2,a5
    1e3c:	004e0e13          	addi	t3,t3,4
    1e40:	fe070ae3          	beqz	a4,1e34 <_malloc_r+0x574>
    1e44:	000e0593          	mv	a1,t3
    1e48:	c51ff06f          	j	1a98 <_malloc_r+0x1d8>
    1e4c:	9f018c13          	addi	s8,gp,-1552 # 7550 <__malloc_current_mallinfo>
    1e50:	000c2703          	lw	a4,0(s8)
    1e54:	00ea0733          	add	a4,s4,a4
    1e58:	00ec2023          	sw	a4,0(s8)
    1e5c:	000ca683          	lw	a3,0(s9)
    1e60:	fff00793          	li	a5,-1
    1e64:	18f68663          	beq	a3,a5,1ff0 <_malloc_r+0x730>
    1e68:	415b87b3          	sub	a5,s7,s5
    1e6c:	00e787b3          	add	a5,a5,a4
    1e70:	00fc2023          	sw	a5,0(s8)
    1e74:	007bfc93          	andi	s9,s7,7
    1e78:	0c0c8c63          	beqz	s9,1f50 <_malloc_r+0x690>
    1e7c:	419b8bb3          	sub	s7,s7,s9
    1e80:	00001737          	lui	a4,0x1
    1e84:	008b8b93          	addi	s7,s7,8
    1e88:	00870713          	addi	a4,a4,8 # 1008 <init>
    1e8c:	014b8a33          	add	s4,s7,s4
    1e90:	41970733          	sub	a4,a4,s9
    1e94:	41470733          	sub	a4,a4,s4
    1e98:	01471713          	slli	a4,a4,0x14
    1e9c:	01475a93          	srli	s5,a4,0x14
    1ea0:	000a8593          	mv	a1,s5
    1ea4:	00090513          	mv	a0,s2
    1ea8:	764000ef          	jal	260c <_sbrk_r>
    1eac:	fff00793          	li	a5,-1
    1eb0:	18f50063          	beq	a0,a5,2030 <_malloc_r+0x770>
    1eb4:	41750533          	sub	a0,a0,s7
    1eb8:	01550a33          	add	s4,a0,s5
    1ebc:	000c2703          	lw	a4,0(s8)
    1ec0:	0179a423          	sw	s7,8(s3)
    1ec4:	001a6793          	ori	a5,s4,1
    1ec8:	00ea8733          	add	a4,s5,a4
    1ecc:	00ec2023          	sw	a4,0(s8)
    1ed0:	00fba223          	sw	a5,4(s7)
    1ed4:	cf3408e3          	beq	s0,s3,1bc4 <_malloc_r+0x304>
    1ed8:	00f00613          	li	a2,15
    1edc:	0b667063          	bgeu	a2,s6,1f7c <_malloc_r+0x6bc>
    1ee0:	00442683          	lw	a3,4(s0)
    1ee4:	ff4b0793          	addi	a5,s6,-12
    1ee8:	ff87f793          	andi	a5,a5,-8
    1eec:	0016f693          	andi	a3,a3,1
    1ef0:	00f6e6b3          	or	a3,a3,a5
    1ef4:	00d42223          	sw	a3,4(s0)
    1ef8:	00500593          	li	a1,5
    1efc:	00f406b3          	add	a3,s0,a5
    1f00:	00b6a223          	sw	a1,4(a3)
    1f04:	00b6a423          	sw	a1,8(a3)
    1f08:	00f66663          	bltu	a2,a5,1f14 <_malloc_r+0x654>
    1f0c:	004ba783          	lw	a5,4(s7)
    1f10:	cb5ff06f          	j	1bc4 <_malloc_r+0x304>
    1f14:	00840593          	addi	a1,s0,8
    1f18:	00090513          	mv	a0,s2
    1f1c:	079000ef          	jal	2794 <_free_r>
    1f20:	0089ab83          	lw	s7,8(s3)
    1f24:	000c2703          	lw	a4,0(s8)
    1f28:	004ba783          	lw	a5,4(s7)
    1f2c:	c99ff06f          	j	1bc4 <_malloc_r+0x304>
    1f30:	010a0a13          	addi	s4,s4,16
    1f34:	c45ff06f          	j	1b78 <_malloc_r+0x2b8>
    1f38:	4026d693          	srai	a3,a3,0x2
    1f3c:	00100793          	li	a5,1
    1f40:	00d797b3          	sll	a5,a5,a3
    1f44:	00f56533          	or	a0,a0,a5
    1f48:	00a9a223          	sw	a0,4(s3)
    1f4c:	d75ff06f          	j	1cc0 <_malloc_r+0x400>
    1f50:	014b8733          	add	a4,s7,s4
    1f54:	40e00733          	neg	a4,a4
    1f58:	01471713          	slli	a4,a4,0x14
    1f5c:	01475a93          	srli	s5,a4,0x14
    1f60:	000a8593          	mv	a1,s5
    1f64:	00090513          	mv	a0,s2
    1f68:	6a4000ef          	jal	260c <_sbrk_r>
    1f6c:	fff00793          	li	a5,-1
    1f70:	f4f512e3          	bne	a0,a5,1eb4 <_malloc_r+0x5f4>
    1f74:	00000a93          	li	s5,0
    1f78:	f45ff06f          	j	1ebc <_malloc_r+0x5fc>
    1f7c:	00812c03          	lw	s8,8(sp)
    1f80:	00100793          	li	a5,1
    1f84:	00fba223          	sw	a5,4(s7)
    1f88:	00090513          	mv	a0,s2
    1f8c:	100000ef          	jal	208c <__malloc_unlock>
    1f90:	00000513          	li	a0,0
    1f94:	01812a03          	lw	s4,24(sp)
    1f98:	01412a83          	lw	s5,20(sp)
    1f9c:	01012b03          	lw	s6,16(sp)
    1fa0:	00c12b83          	lw	s7,12(sp)
    1fa4:	00412c83          	lw	s9,4(sp)
    1fa8:	9a5ff06f          	j	194c <_malloc_r+0x8c>
    1fac:	05400693          	li	a3,84
    1fb0:	04e6e463          	bltu	a3,a4,1ff8 <_malloc_r+0x738>
    1fb4:	00c7d713          	srli	a4,a5,0xc
    1fb8:	06f70613          	addi	a2,a4,111
    1fbc:	06e70693          	addi	a3,a4,110
    1fc0:	00361613          	slli	a2,a2,0x3
    1fc4:	cd1ff06f          	j	1c94 <_malloc_r+0x3d4>
    1fc8:	15400713          	li	a4,340
    1fcc:	04f76463          	bltu	a4,a5,2014 <_malloc_r+0x754>
    1fd0:	00f4d793          	srli	a5,s1,0xf
    1fd4:	07878593          	addi	a1,a5,120
    1fd8:	07778813          	addi	a6,a5,119
    1fdc:	00359613          	slli	a2,a1,0x3
    1fe0:	9c1ff06f          	j	19a0 <_malloc_r+0xe0>
    1fe4:	0089a403          	lw	s0,8(s3)
    1fe8:	00442783          	lw	a5,4(s0)
    1fec:	c01ff06f          	j	1bec <_malloc_r+0x32c>
    1ff0:	017ca023          	sw	s7,0(s9)
    1ff4:	e81ff06f          	j	1e74 <_malloc_r+0x5b4>
    1ff8:	15400693          	li	a3,340
    1ffc:	04e6e463          	bltu	a3,a4,2044 <_malloc_r+0x784>
    2000:	00f7d713          	srli	a4,a5,0xf
    2004:	07870613          	addi	a2,a4,120
    2008:	07770693          	addi	a3,a4,119
    200c:	00361613          	slli	a2,a2,0x3
    2010:	c85ff06f          	j	1c94 <_malloc_r+0x3d4>
    2014:	55400713          	li	a4,1364
    2018:	04f76463          	bltu	a4,a5,2060 <_malloc_r+0x7a0>
    201c:	0124d793          	srli	a5,s1,0x12
    2020:	07d78593          	addi	a1,a5,125
    2024:	07c78813          	addi	a6,a5,124
    2028:	00359613          	slli	a2,a1,0x3
    202c:	975ff06f          	j	19a0 <_malloc_r+0xe0>
    2030:	ff8c8c93          	addi	s9,s9,-8
    2034:	019a0a33          	add	s4,s4,s9
    2038:	417a0a33          	sub	s4,s4,s7
    203c:	00000a93          	li	s5,0
    2040:	e7dff06f          	j	1ebc <_malloc_r+0x5fc>
    2044:	55400693          	li	a3,1364
    2048:	02e6e463          	bltu	a3,a4,2070 <_malloc_r+0x7b0>
    204c:	0127d713          	srli	a4,a5,0x12
    2050:	07d70613          	addi	a2,a4,125
    2054:	07c70693          	addi	a3,a4,124
    2058:	00361613          	slli	a2,a2,0x3
    205c:	c39ff06f          	j	1c94 <_malloc_r+0x3d4>
    2060:	3f800613          	li	a2,1016
    2064:	07f00593          	li	a1,127
    2068:	07e00813          	li	a6,126
    206c:	935ff06f          	j	19a0 <_malloc_r+0xe0>
    2070:	3f800613          	li	a2,1016
    2074:	07e00693          	li	a3,126
    2078:	c1dff06f          	j	1c94 <_malloc_r+0x3d4>
    207c:	0049a783          	lw	a5,4(s3)
    2080:	da1ff06f          	j	1e20 <_malloc_r+0x560>

00002084 <__malloc_lock>:
    2084:	86418513          	addi	a0,gp,-1948 # 73c4 <__lock___malloc_recursive_mutex>
    2088:	f40ff06f          	j	17c8 <__retarget_lock_acquire_recursive>

0000208c <__malloc_unlock>:
    208c:	86418513          	addi	a0,gp,-1948 # 73c4 <__lock___malloc_recursive_mutex>
    2090:	f50ff06f          	j	17e0 <__retarget_lock_release_recursive>

00002094 <_fclose_r>:
    2094:	ff010113          	addi	sp,sp,-16
    2098:	00112623          	sw	ra,12(sp)
    209c:	01212023          	sw	s2,0(sp)
    20a0:	0e058263          	beqz	a1,2184 <_fclose_r+0xf0>
    20a4:	00812423          	sw	s0,8(sp)
    20a8:	00912223          	sw	s1,4(sp)
    20ac:	00058413          	mv	s0,a1
    20b0:	00050493          	mv	s1,a0
    20b4:	00050663          	beqz	a0,20c0 <_fclose_r+0x2c>
    20b8:	03452783          	lw	a5,52(a0)
    20bc:	10078063          	beqz	a5,21bc <_fclose_r+0x128>
    20c0:	06442783          	lw	a5,100(s0)
    20c4:	00c41703          	lh	a4,12(s0)
    20c8:	0017f793          	andi	a5,a5,1
    20cc:	0a079663          	bnez	a5,2178 <_fclose_r+0xe4>
    20d0:	20077713          	andi	a4,a4,512
    20d4:	0e070863          	beqz	a4,21c4 <_fclose_r+0x130>
    20d8:	00040593          	mv	a1,s0
    20dc:	00048513          	mv	a0,s1
    20e0:	130000ef          	jal	2210 <__sflush_r>
    20e4:	02c42783          	lw	a5,44(s0)
    20e8:	00050913          	mv	s2,a0
    20ec:	00078a63          	beqz	a5,2100 <_fclose_r+0x6c>
    20f0:	01c42583          	lw	a1,28(s0)
    20f4:	00048513          	mv	a0,s1
    20f8:	000780e7          	jalr	a5
    20fc:	0a054063          	bltz	a0,219c <_fclose_r+0x108>
    2100:	00c45783          	lhu	a5,12(s0)
    2104:	0807f793          	andi	a5,a5,128
    2108:	0a079263          	bnez	a5,21ac <_fclose_r+0x118>
    210c:	03042583          	lw	a1,48(s0)
    2110:	00058c63          	beqz	a1,2128 <_fclose_r+0x94>
    2114:	04040793          	addi	a5,s0,64
    2118:	00f58663          	beq	a1,a5,2124 <_fclose_r+0x90>
    211c:	00048513          	mv	a0,s1
    2120:	674000ef          	jal	2794 <_free_r>
    2124:	02042823          	sw	zero,48(s0)
    2128:	04442583          	lw	a1,68(s0)
    212c:	00058863          	beqz	a1,213c <_fclose_r+0xa8>
    2130:	00048513          	mv	a0,s1
    2134:	660000ef          	jal	2794 <_free_r>
    2138:	04042223          	sw	zero,68(s0)
    213c:	be8ff0ef          	jal	1524 <__sfp_lock_acquire>
    2140:	06442783          	lw	a5,100(s0)
    2144:	00041623          	sh	zero,12(s0)
    2148:	0017f793          	andi	a5,a5,1
    214c:	0a078663          	beqz	a5,21f8 <_fclose_r+0x164>
    2150:	05842503          	lw	a0,88(s0)
    2154:	e6cff0ef          	jal	17c0 <__retarget_lock_close_recursive>
    2158:	bd4ff0ef          	jal	152c <__sfp_lock_release>
    215c:	00c12083          	lw	ra,12(sp)
    2160:	00812403          	lw	s0,8(sp)
    2164:	00412483          	lw	s1,4(sp)
    2168:	00090513          	mv	a0,s2
    216c:	00012903          	lw	s2,0(sp)
    2170:	01010113          	addi	sp,sp,16
    2174:	00008067          	ret
    2178:	f60710e3          	bnez	a4,20d8 <_fclose_r+0x44>
    217c:	00812403          	lw	s0,8(sp)
    2180:	00412483          	lw	s1,4(sp)
    2184:	00000913          	li	s2,0
    2188:	00c12083          	lw	ra,12(sp)
    218c:	00090513          	mv	a0,s2
    2190:	00012903          	lw	s2,0(sp)
    2194:	01010113          	addi	sp,sp,16
    2198:	00008067          	ret
    219c:	00c45783          	lhu	a5,12(s0)
    21a0:	fff00913          	li	s2,-1
    21a4:	0807f793          	andi	a5,a5,128
    21a8:	f60782e3          	beqz	a5,210c <_fclose_r+0x78>
    21ac:	01042583          	lw	a1,16(s0)
    21b0:	00048513          	mv	a0,s1
    21b4:	5e0000ef          	jal	2794 <_free_r>
    21b8:	f55ff06f          	j	210c <_fclose_r+0x78>
    21bc:	b08ff0ef          	jal	14c4 <__sinit>
    21c0:	f01ff06f          	j	20c0 <_fclose_r+0x2c>
    21c4:	05842503          	lw	a0,88(s0)
    21c8:	e00ff0ef          	jal	17c8 <__retarget_lock_acquire_recursive>
    21cc:	00c41783          	lh	a5,12(s0)
    21d0:	f00794e3          	bnez	a5,20d8 <_fclose_r+0x44>
    21d4:	06442783          	lw	a5,100(s0)
    21d8:	0017f793          	andi	a5,a5,1
    21dc:	fa0790e3          	bnez	a5,217c <_fclose_r+0xe8>
    21e0:	05842503          	lw	a0,88(s0)
    21e4:	00000913          	li	s2,0
    21e8:	df8ff0ef          	jal	17e0 <__retarget_lock_release_recursive>
    21ec:	00812403          	lw	s0,8(sp)
    21f0:	00412483          	lw	s1,4(sp)
    21f4:	f95ff06f          	j	2188 <_fclose_r+0xf4>
    21f8:	05842503          	lw	a0,88(s0)
    21fc:	de4ff0ef          	jal	17e0 <__retarget_lock_release_recursive>
    2200:	f51ff06f          	j	2150 <_fclose_r+0xbc>

00002204 <fclose>:
    2204:	00050593          	mv	a1,a0
    2208:	81c1a503          	lw	a0,-2020(gp) # 737c <_impure_ptr>
    220c:	e89ff06f          	j	2094 <_fclose_r>

00002210 <__sflush_r>:
    2210:	00c59703          	lh	a4,12(a1)
    2214:	fe010113          	addi	sp,sp,-32
    2218:	00812c23          	sw	s0,24(sp)
    221c:	01312623          	sw	s3,12(sp)
    2220:	00112e23          	sw	ra,28(sp)
    2224:	00877793          	andi	a5,a4,8
    2228:	00058413          	mv	s0,a1
    222c:	00050993          	mv	s3,a0
    2230:	12079063          	bnez	a5,2350 <__sflush_r+0x140>
    2234:	000017b7          	lui	a5,0x1
    2238:	80078793          	addi	a5,a5,-2048 # 800 <CUSTOM2+0x7a5>
    223c:	0045a683          	lw	a3,4(a1)
    2240:	00f767b3          	or	a5,a4,a5
    2244:	00f59623          	sh	a5,12(a1)
    2248:	18d05263          	blez	a3,23cc <__sflush_r+0x1bc>
    224c:	02842803          	lw	a6,40(s0)
    2250:	0e080463          	beqz	a6,2338 <__sflush_r+0x128>
    2254:	00912a23          	sw	s1,20(sp)
    2258:	01371693          	slli	a3,a4,0x13
    225c:	0009a483          	lw	s1,0(s3)
    2260:	0009a023          	sw	zero,0(s3)
    2264:	01c42583          	lw	a1,28(s0)
    2268:	1606ce63          	bltz	a3,23e4 <__sflush_r+0x1d4>
    226c:	00000613          	li	a2,0
    2270:	00100693          	li	a3,1
    2274:	00098513          	mv	a0,s3
    2278:	000800e7          	jalr	a6
    227c:	fff00793          	li	a5,-1
    2280:	00050613          	mv	a2,a0
    2284:	1af50463          	beq	a0,a5,242c <__sflush_r+0x21c>
    2288:	00c41783          	lh	a5,12(s0)
    228c:	02842803          	lw	a6,40(s0)
    2290:	01c42583          	lw	a1,28(s0)
    2294:	0047f793          	andi	a5,a5,4
    2298:	00078e63          	beqz	a5,22b4 <__sflush_r+0xa4>
    229c:	00442703          	lw	a4,4(s0)
    22a0:	03042783          	lw	a5,48(s0)
    22a4:	40e60633          	sub	a2,a2,a4
    22a8:	00078663          	beqz	a5,22b4 <__sflush_r+0xa4>
    22ac:	03c42783          	lw	a5,60(s0)
    22b0:	40f60633          	sub	a2,a2,a5
    22b4:	00000693          	li	a3,0
    22b8:	00098513          	mv	a0,s3
    22bc:	000800e7          	jalr	a6
    22c0:	fff00793          	li	a5,-1
    22c4:	12f51463          	bne	a0,a5,23ec <__sflush_r+0x1dc>
    22c8:	0009a683          	lw	a3,0(s3)
    22cc:	01d00793          	li	a5,29
    22d0:	00c41703          	lh	a4,12(s0)
    22d4:	16d7ea63          	bltu	a5,a3,2448 <__sflush_r+0x238>
    22d8:	204007b7          	lui	a5,0x20400
    22dc:	00178793          	addi	a5,a5,1 # 20400001 <__freertos_irq_stack_top+0x203f7a81>
    22e0:	00d7d7b3          	srl	a5,a5,a3
    22e4:	0017f793          	andi	a5,a5,1
    22e8:	16078063          	beqz	a5,2448 <__sflush_r+0x238>
    22ec:	01042603          	lw	a2,16(s0)
    22f0:	fffff7b7          	lui	a5,0xfffff
    22f4:	7ff78793          	addi	a5,a5,2047 # fffff7ff <__freertos_irq_stack_top+0xffff727f>
    22f8:	00f777b3          	and	a5,a4,a5
    22fc:	00f41623          	sh	a5,12(s0)
    2300:	00042223          	sw	zero,4(s0)
    2304:	00c42023          	sw	a2,0(s0)
    2308:	01371793          	slli	a5,a4,0x13
    230c:	0007d463          	bgez	a5,2314 <__sflush_r+0x104>
    2310:	10068263          	beqz	a3,2414 <__sflush_r+0x204>
    2314:	03042583          	lw	a1,48(s0)
    2318:	0099a023          	sw	s1,0(s3)
    231c:	10058463          	beqz	a1,2424 <__sflush_r+0x214>
    2320:	04040793          	addi	a5,s0,64
    2324:	00f58663          	beq	a1,a5,2330 <__sflush_r+0x120>
    2328:	00098513          	mv	a0,s3
    232c:	468000ef          	jal	2794 <_free_r>
    2330:	01412483          	lw	s1,20(sp)
    2334:	02042823          	sw	zero,48(s0)
    2338:	00000513          	li	a0,0
    233c:	01c12083          	lw	ra,28(sp)
    2340:	01812403          	lw	s0,24(sp)
    2344:	00c12983          	lw	s3,12(sp)
    2348:	02010113          	addi	sp,sp,32
    234c:	00008067          	ret
    2350:	01212823          	sw	s2,16(sp)
    2354:	0105a903          	lw	s2,16(a1)
    2358:	08090263          	beqz	s2,23dc <__sflush_r+0x1cc>
    235c:	00912a23          	sw	s1,20(sp)
    2360:	0005a483          	lw	s1,0(a1)
    2364:	00377713          	andi	a4,a4,3
    2368:	0125a023          	sw	s2,0(a1)
    236c:	412484b3          	sub	s1,s1,s2
    2370:	00000793          	li	a5,0
    2374:	00071463          	bnez	a4,237c <__sflush_r+0x16c>
    2378:	0145a783          	lw	a5,20(a1)
    237c:	00f42423          	sw	a5,8(s0)
    2380:	00904863          	bgtz	s1,2390 <__sflush_r+0x180>
    2384:	0540006f          	j	23d8 <__sflush_r+0x1c8>
    2388:	00a90933          	add	s2,s2,a0
    238c:	04905663          	blez	s1,23d8 <__sflush_r+0x1c8>
    2390:	02442783          	lw	a5,36(s0)
    2394:	01c42583          	lw	a1,28(s0)
    2398:	00048693          	mv	a3,s1
    239c:	00090613          	mv	a2,s2
    23a0:	00098513          	mv	a0,s3
    23a4:	000780e7          	jalr	a5
    23a8:	40a484b3          	sub	s1,s1,a0
    23ac:	fca04ee3          	bgtz	a0,2388 <__sflush_r+0x178>
    23b0:	00c41703          	lh	a4,12(s0)
    23b4:	01012903          	lw	s2,16(sp)
    23b8:	04076713          	ori	a4,a4,64
    23bc:	01412483          	lw	s1,20(sp)
    23c0:	00e41623          	sh	a4,12(s0)
    23c4:	fff00513          	li	a0,-1
    23c8:	f75ff06f          	j	233c <__sflush_r+0x12c>
    23cc:	03c5a683          	lw	a3,60(a1)
    23d0:	e6d04ee3          	bgtz	a3,224c <__sflush_r+0x3c>
    23d4:	f65ff06f          	j	2338 <__sflush_r+0x128>
    23d8:	01412483          	lw	s1,20(sp)
    23dc:	01012903          	lw	s2,16(sp)
    23e0:	f59ff06f          	j	2338 <__sflush_r+0x128>
    23e4:	05042603          	lw	a2,80(s0)
    23e8:	eadff06f          	j	2294 <__sflush_r+0x84>
    23ec:	00c41703          	lh	a4,12(s0)
    23f0:	01042683          	lw	a3,16(s0)
    23f4:	fffff7b7          	lui	a5,0xfffff
    23f8:	7ff78793          	addi	a5,a5,2047 # fffff7ff <__freertos_irq_stack_top+0xffff727f>
    23fc:	00f777b3          	and	a5,a4,a5
    2400:	00f41623          	sh	a5,12(s0)
    2404:	00042223          	sw	zero,4(s0)
    2408:	00d42023          	sw	a3,0(s0)
    240c:	01371793          	slli	a5,a4,0x13
    2410:	f007d2e3          	bgez	a5,2314 <__sflush_r+0x104>
    2414:	03042583          	lw	a1,48(s0)
    2418:	04a42823          	sw	a0,80(s0)
    241c:	0099a023          	sw	s1,0(s3)
    2420:	f00590e3          	bnez	a1,2320 <__sflush_r+0x110>
    2424:	01412483          	lw	s1,20(sp)
    2428:	f11ff06f          	j	2338 <__sflush_r+0x128>
    242c:	0009a783          	lw	a5,0(s3)
    2430:	e4078ce3          	beqz	a5,2288 <__sflush_r+0x78>
    2434:	01d00713          	li	a4,29
    2438:	00e78c63          	beq	a5,a4,2450 <__sflush_r+0x240>
    243c:	01600713          	li	a4,22
    2440:	00e78863          	beq	a5,a4,2450 <__sflush_r+0x240>
    2444:	00c41703          	lh	a4,12(s0)
    2448:	04076713          	ori	a4,a4,64
    244c:	f71ff06f          	j	23bc <__sflush_r+0x1ac>
    2450:	0099a023          	sw	s1,0(s3)
    2454:	01412483          	lw	s1,20(sp)
    2458:	ee1ff06f          	j	2338 <__sflush_r+0x128>

0000245c <_fflush_r>:
    245c:	ff010113          	addi	sp,sp,-16
    2460:	00812423          	sw	s0,8(sp)
    2464:	00912223          	sw	s1,4(sp)
    2468:	00112623          	sw	ra,12(sp)
    246c:	01212023          	sw	s2,0(sp)
    2470:	00050493          	mv	s1,a0
    2474:	00058413          	mv	s0,a1
    2478:	00050663          	beqz	a0,2484 <_fflush_r+0x28>
    247c:	03452783          	lw	a5,52(a0)
    2480:	0a078a63          	beqz	a5,2534 <_fflush_r+0xd8>
    2484:	00c41783          	lh	a5,12(s0)
    2488:	00000913          	li	s2,0
    248c:	04078063          	beqz	a5,24cc <_fflush_r+0x70>
    2490:	06442703          	lw	a4,100(s0)
    2494:	00177713          	andi	a4,a4,1
    2498:	00071663          	bnez	a4,24a4 <_fflush_r+0x48>
    249c:	2007f793          	andi	a5,a5,512
    24a0:	04078463          	beqz	a5,24e8 <_fflush_r+0x8c>
    24a4:	00040593          	mv	a1,s0
    24a8:	00048513          	mv	a0,s1
    24ac:	d65ff0ef          	jal	2210 <__sflush_r>
    24b0:	06442783          	lw	a5,100(s0)
    24b4:	00050913          	mv	s2,a0
    24b8:	0017f793          	andi	a5,a5,1
    24bc:	00079863          	bnez	a5,24cc <_fflush_r+0x70>
    24c0:	00c45783          	lhu	a5,12(s0)
    24c4:	2007f793          	andi	a5,a5,512
    24c8:	04078463          	beqz	a5,2510 <_fflush_r+0xb4>
    24cc:	00c12083          	lw	ra,12(sp)
    24d0:	00812403          	lw	s0,8(sp)
    24d4:	00412483          	lw	s1,4(sp)
    24d8:	00090513          	mv	a0,s2
    24dc:	00012903          	lw	s2,0(sp)
    24e0:	01010113          	addi	sp,sp,16
    24e4:	00008067          	ret
    24e8:	05842503          	lw	a0,88(s0)
    24ec:	adcff0ef          	jal	17c8 <__retarget_lock_acquire_recursive>
    24f0:	00040593          	mv	a1,s0
    24f4:	00048513          	mv	a0,s1
    24f8:	d19ff0ef          	jal	2210 <__sflush_r>
    24fc:	06442783          	lw	a5,100(s0)
    2500:	00050913          	mv	s2,a0
    2504:	0017f793          	andi	a5,a5,1
    2508:	fc0792e3          	bnez	a5,24cc <_fflush_r+0x70>
    250c:	fb5ff06f          	j	24c0 <_fflush_r+0x64>
    2510:	05842503          	lw	a0,88(s0)
    2514:	accff0ef          	jal	17e0 <__retarget_lock_release_recursive>
    2518:	00c12083          	lw	ra,12(sp)
    251c:	00812403          	lw	s0,8(sp)
    2520:	00412483          	lw	s1,4(sp)
    2524:	00090513          	mv	a0,s2
    2528:	00012903          	lw	s2,0(sp)
    252c:	01010113          	addi	sp,sp,16
    2530:	00008067          	ret
    2534:	f91fe0ef          	jal	14c4 <__sinit>
    2538:	f4dff06f          	j	2484 <_fflush_r+0x28>

0000253c <fflush>:
    253c:	0a050a63          	beqz	a0,25f0 <fflush+0xb4>
    2540:	ff010113          	addi	sp,sp,-16
    2544:	00812423          	sw	s0,8(sp)
    2548:	01212023          	sw	s2,0(sp)
    254c:	00112623          	sw	ra,12(sp)
    2550:	00912223          	sw	s1,4(sp)
    2554:	81c1a903          	lw	s2,-2020(gp) # 737c <_impure_ptr>
    2558:	00050413          	mv	s0,a0
    255c:	00090663          	beqz	s2,2568 <fflush+0x2c>
    2560:	03492783          	lw	a5,52(s2)
    2564:	06078463          	beqz	a5,25cc <fflush+0x90>
    2568:	00c41783          	lh	a5,12(s0)
    256c:	00000493          	li	s1,0
    2570:	04078063          	beqz	a5,25b0 <fflush+0x74>
    2574:	06442703          	lw	a4,100(s0)
    2578:	00177713          	andi	a4,a4,1
    257c:	00071663          	bnez	a4,2588 <fflush+0x4c>
    2580:	2007f793          	andi	a5,a5,512
    2584:	04078a63          	beqz	a5,25d8 <fflush+0x9c>
    2588:	00040593          	mv	a1,s0
    258c:	00090513          	mv	a0,s2
    2590:	c81ff0ef          	jal	2210 <__sflush_r>
    2594:	06442783          	lw	a5,100(s0)
    2598:	00050493          	mv	s1,a0
    259c:	0017f793          	andi	a5,a5,1
    25a0:	00079863          	bnez	a5,25b0 <fflush+0x74>
    25a4:	00c45783          	lhu	a5,12(s0)
    25a8:	2007f793          	andi	a5,a5,512
    25ac:	02078c63          	beqz	a5,25e4 <fflush+0xa8>
    25b0:	00c12083          	lw	ra,12(sp)
    25b4:	00812403          	lw	s0,8(sp)
    25b8:	00012903          	lw	s2,0(sp)
    25bc:	00048513          	mv	a0,s1
    25c0:	00412483          	lw	s1,4(sp)
    25c4:	01010113          	addi	sp,sp,16
    25c8:	00008067          	ret
    25cc:	00090513          	mv	a0,s2
    25d0:	ef5fe0ef          	jal	14c4 <__sinit>
    25d4:	f95ff06f          	j	2568 <fflush+0x2c>
    25d8:	05842503          	lw	a0,88(s0)
    25dc:	9ecff0ef          	jal	17c8 <__retarget_lock_acquire_recursive>
    25e0:	fa9ff06f          	j	2588 <fflush+0x4c>
    25e4:	05842503          	lw	a0,88(s0)
    25e8:	9f8ff0ef          	jal	17e0 <__retarget_lock_release_recursive>
    25ec:	fc5ff06f          	j	25b0 <fflush+0x74>
    25f0:	00005617          	auipc	a2,0x5
    25f4:	96860613          	addi	a2,a2,-1688 # 6f58 <__sglue>
    25f8:	00000597          	auipc	a1,0x0
    25fc:	e6458593          	addi	a1,a1,-412 # 245c <_fflush_r>
    2600:	00005517          	auipc	a0,0x5
    2604:	81850513          	addi	a0,a0,-2024 # 6e18 <_impure_data>
    2608:	f8dfe06f          	j	1594 <_fwalk_sglue>

0000260c <_sbrk_r>:
    260c:	ff010113          	addi	sp,sp,-16
    2610:	00812423          	sw	s0,8(sp)
    2614:	00050413          	mv	s0,a0
    2618:	00058513          	mv	a0,a1
    261c:	8801a023          	sw	zero,-1920(gp) # 73e0 <errno>
    2620:	00112623          	sw	ra,12(sp)
    2624:	5c0030ef          	jal	5be4 <_sbrk>
    2628:	fff00793          	li	a5,-1
    262c:	00f50a63          	beq	a0,a5,2640 <_sbrk_r+0x34>
    2630:	00c12083          	lw	ra,12(sp)
    2634:	00812403          	lw	s0,8(sp)
    2638:	01010113          	addi	sp,sp,16
    263c:	00008067          	ret
    2640:	8801a783          	lw	a5,-1920(gp) # 73e0 <errno>
    2644:	fe0786e3          	beqz	a5,2630 <_sbrk_r+0x24>
    2648:	00c12083          	lw	ra,12(sp)
    264c:	00f42023          	sw	a5,0(s0)
    2650:	00812403          	lw	s0,8(sp)
    2654:	01010113          	addi	sp,sp,16
    2658:	00008067          	ret

0000265c <_malloc_trim_r>:
    265c:	fe010113          	addi	sp,sp,-32
    2660:	00812c23          	sw	s0,24(sp)
    2664:	00912a23          	sw	s1,20(sp)
    2668:	01212823          	sw	s2,16(sp)
    266c:	01312623          	sw	s3,12(sp)
    2670:	01412423          	sw	s4,8(sp)
    2674:	00058993          	mv	s3,a1
    2678:	00112e23          	sw	ra,28(sp)
    267c:	00050913          	mv	s2,a0
    2680:	00005a17          	auipc	s4,0x5
    2684:	8e4a0a13          	addi	s4,s4,-1820 # 6f64 <__malloc_av_>
    2688:	9fdff0ef          	jal	2084 <__malloc_lock>
    268c:	008a2703          	lw	a4,8(s4)
    2690:	000017b7          	lui	a5,0x1
    2694:	fef78793          	addi	a5,a5,-17 # fef <CUSTOM2+0xf94>
    2698:	00472483          	lw	s1,4(a4)
    269c:	00001737          	lui	a4,0x1
    26a0:	ffc4f493          	andi	s1,s1,-4
    26a4:	00f48433          	add	s0,s1,a5
    26a8:	41340433          	sub	s0,s0,s3
    26ac:	00c45413          	srli	s0,s0,0xc
    26b0:	fff40413          	addi	s0,s0,-1
    26b4:	00c41413          	slli	s0,s0,0xc
    26b8:	00e44e63          	blt	s0,a4,26d4 <_malloc_trim_r+0x78>
    26bc:	00000593          	li	a1,0
    26c0:	00090513          	mv	a0,s2
    26c4:	f49ff0ef          	jal	260c <_sbrk_r>
    26c8:	008a2783          	lw	a5,8(s4)
    26cc:	009787b3          	add	a5,a5,s1
    26d0:	02f50863          	beq	a0,a5,2700 <_malloc_trim_r+0xa4>
    26d4:	00090513          	mv	a0,s2
    26d8:	9b5ff0ef          	jal	208c <__malloc_unlock>
    26dc:	01c12083          	lw	ra,28(sp)
    26e0:	01812403          	lw	s0,24(sp)
    26e4:	01412483          	lw	s1,20(sp)
    26e8:	01012903          	lw	s2,16(sp)
    26ec:	00c12983          	lw	s3,12(sp)
    26f0:	00812a03          	lw	s4,8(sp)
    26f4:	00000513          	li	a0,0
    26f8:	02010113          	addi	sp,sp,32
    26fc:	00008067          	ret
    2700:	408005b3          	neg	a1,s0
    2704:	00090513          	mv	a0,s2
    2708:	f05ff0ef          	jal	260c <_sbrk_r>
    270c:	fff00793          	li	a5,-1
    2710:	04f50863          	beq	a0,a5,2760 <_malloc_trim_r+0x104>
    2714:	9f018713          	addi	a4,gp,-1552 # 7550 <__malloc_current_mallinfo>
    2718:	00072783          	lw	a5,0(a4) # 1000 <_start>
    271c:	008a2683          	lw	a3,8(s4)
    2720:	408484b3          	sub	s1,s1,s0
    2724:	0014e493          	ori	s1,s1,1
    2728:	408787b3          	sub	a5,a5,s0
    272c:	00090513          	mv	a0,s2
    2730:	0096a223          	sw	s1,4(a3)
    2734:	00f72023          	sw	a5,0(a4)
    2738:	955ff0ef          	jal	208c <__malloc_unlock>
    273c:	01c12083          	lw	ra,28(sp)
    2740:	01812403          	lw	s0,24(sp)
    2744:	01412483          	lw	s1,20(sp)
    2748:	01012903          	lw	s2,16(sp)
    274c:	00c12983          	lw	s3,12(sp)
    2750:	00812a03          	lw	s4,8(sp)
    2754:	00100513          	li	a0,1
    2758:	02010113          	addi	sp,sp,32
    275c:	00008067          	ret
    2760:	00000593          	li	a1,0
    2764:	00090513          	mv	a0,s2
    2768:	ea5ff0ef          	jal	260c <_sbrk_r>
    276c:	008a2703          	lw	a4,8(s4)
    2770:	00f00693          	li	a3,15
    2774:	40e507b3          	sub	a5,a0,a4
    2778:	f4f6dee3          	bge	a3,a5,26d4 <_malloc_trim_r+0x78>
    277c:	8201a683          	lw	a3,-2016(gp) # 7380 <__malloc_sbrk_base>
    2780:	40d50533          	sub	a0,a0,a3
    2784:	0017e793          	ori	a5,a5,1
    2788:	9ea1a823          	sw	a0,-1552(gp) # 7550 <__malloc_current_mallinfo>
    278c:	00f72223          	sw	a5,4(a4)
    2790:	f45ff06f          	j	26d4 <_malloc_trim_r+0x78>

00002794 <_free_r>:
    2794:	18058263          	beqz	a1,2918 <_free_r+0x184>
    2798:	ff010113          	addi	sp,sp,-16
    279c:	00812423          	sw	s0,8(sp)
    27a0:	00912223          	sw	s1,4(sp)
    27a4:	00058413          	mv	s0,a1
    27a8:	00050493          	mv	s1,a0
    27ac:	00112623          	sw	ra,12(sp)
    27b0:	8d5ff0ef          	jal	2084 <__malloc_lock>
    27b4:	ffc42583          	lw	a1,-4(s0)
    27b8:	ff840713          	addi	a4,s0,-8
    27bc:	00004517          	auipc	a0,0x4
    27c0:	7a850513          	addi	a0,a0,1960 # 6f64 <__malloc_av_>
    27c4:	ffe5f793          	andi	a5,a1,-2
    27c8:	00f70633          	add	a2,a4,a5
    27cc:	00462683          	lw	a3,4(a2)
    27d0:	00852803          	lw	a6,8(a0)
    27d4:	ffc6f693          	andi	a3,a3,-4
    27d8:	1ac80263          	beq	a6,a2,297c <_free_r+0x1e8>
    27dc:	00d62223          	sw	a3,4(a2)
    27e0:	0015f593          	andi	a1,a1,1
    27e4:	00d60833          	add	a6,a2,a3
    27e8:	0a059063          	bnez	a1,2888 <_free_r+0xf4>
    27ec:	ff842303          	lw	t1,-8(s0)
    27f0:	00482583          	lw	a1,4(a6)
    27f4:	00004897          	auipc	a7,0x4
    27f8:	77888893          	addi	a7,a7,1912 # 6f6c <__malloc_av_+0x8>
    27fc:	40670733          	sub	a4,a4,t1
    2800:	00872803          	lw	a6,8(a4)
    2804:	006787b3          	add	a5,a5,t1
    2808:	0015f593          	andi	a1,a1,1
    280c:	15180263          	beq	a6,a7,2950 <_free_r+0x1bc>
    2810:	00c72303          	lw	t1,12(a4)
    2814:	00682623          	sw	t1,12(a6)
    2818:	01032423          	sw	a6,8(t1)
    281c:	1a058663          	beqz	a1,29c8 <_free_r+0x234>
    2820:	0017e693          	ori	a3,a5,1
    2824:	00d72223          	sw	a3,4(a4)
    2828:	00f62023          	sw	a5,0(a2)
    282c:	1ff00693          	li	a3,511
    2830:	06f6ec63          	bltu	a3,a5,28a8 <_free_r+0x114>
    2834:	ff87f693          	andi	a3,a5,-8
    2838:	00868693          	addi	a3,a3,8
    283c:	00452583          	lw	a1,4(a0)
    2840:	00d506b3          	add	a3,a0,a3
    2844:	0006a603          	lw	a2,0(a3)
    2848:	0057d813          	srli	a6,a5,0x5
    284c:	00100793          	li	a5,1
    2850:	010797b3          	sll	a5,a5,a6
    2854:	00b7e7b3          	or	a5,a5,a1
    2858:	ff868593          	addi	a1,a3,-8
    285c:	00b72623          	sw	a1,12(a4)
    2860:	00c72423          	sw	a2,8(a4)
    2864:	00f52223          	sw	a5,4(a0)
    2868:	00e6a023          	sw	a4,0(a3)
    286c:	00e62623          	sw	a4,12(a2)
    2870:	00812403          	lw	s0,8(sp)
    2874:	00c12083          	lw	ra,12(sp)
    2878:	00048513          	mv	a0,s1
    287c:	00412483          	lw	s1,4(sp)
    2880:	01010113          	addi	sp,sp,16
    2884:	809ff06f          	j	208c <__malloc_unlock>
    2888:	00482583          	lw	a1,4(a6)
    288c:	0015f593          	andi	a1,a1,1
    2890:	08058663          	beqz	a1,291c <_free_r+0x188>
    2894:	0017e693          	ori	a3,a5,1
    2898:	fed42e23          	sw	a3,-4(s0)
    289c:	00f62023          	sw	a5,0(a2)
    28a0:	1ff00693          	li	a3,511
    28a4:	f8f6f8e3          	bgeu	a3,a5,2834 <_free_r+0xa0>
    28a8:	0097d693          	srli	a3,a5,0x9
    28ac:	00400613          	li	a2,4
    28b0:	12d66063          	bltu	a2,a3,29d0 <_free_r+0x23c>
    28b4:	0067d693          	srli	a3,a5,0x6
    28b8:	03968593          	addi	a1,a3,57
    28bc:	03868613          	addi	a2,a3,56
    28c0:	00359593          	slli	a1,a1,0x3
    28c4:	00b505b3          	add	a1,a0,a1
    28c8:	0005a683          	lw	a3,0(a1)
    28cc:	ff858593          	addi	a1,a1,-8
    28d0:	00d59863          	bne	a1,a3,28e0 <_free_r+0x14c>
    28d4:	1540006f          	j	2a28 <_free_r+0x294>
    28d8:	0086a683          	lw	a3,8(a3)
    28dc:	00d58863          	beq	a1,a3,28ec <_free_r+0x158>
    28e0:	0046a603          	lw	a2,4(a3)
    28e4:	ffc67613          	andi	a2,a2,-4
    28e8:	fec7e8e3          	bltu	a5,a2,28d8 <_free_r+0x144>
    28ec:	00c6a583          	lw	a1,12(a3)
    28f0:	00b72623          	sw	a1,12(a4)
    28f4:	00d72423          	sw	a3,8(a4)
    28f8:	00812403          	lw	s0,8(sp)
    28fc:	00c12083          	lw	ra,12(sp)
    2900:	00e5a423          	sw	a4,8(a1)
    2904:	00048513          	mv	a0,s1
    2908:	00412483          	lw	s1,4(sp)
    290c:	00e6a623          	sw	a4,12(a3)
    2910:	01010113          	addi	sp,sp,16
    2914:	f78ff06f          	j	208c <__malloc_unlock>
    2918:	00008067          	ret
    291c:	00d787b3          	add	a5,a5,a3
    2920:	00004897          	auipc	a7,0x4
    2924:	64c88893          	addi	a7,a7,1612 # 6f6c <__malloc_av_+0x8>
    2928:	00862683          	lw	a3,8(a2)
    292c:	0d168c63          	beq	a3,a7,2a04 <_free_r+0x270>
    2930:	00c62803          	lw	a6,12(a2)
    2934:	0017e593          	ori	a1,a5,1
    2938:	00f70633          	add	a2,a4,a5
    293c:	0106a623          	sw	a6,12(a3)
    2940:	00d82423          	sw	a3,8(a6)
    2944:	00b72223          	sw	a1,4(a4)
    2948:	00f62023          	sw	a5,0(a2)
    294c:	ee1ff06f          	j	282c <_free_r+0x98>
    2950:	12059c63          	bnez	a1,2a88 <_free_r+0x2f4>
    2954:	00862583          	lw	a1,8(a2)
    2958:	00c62603          	lw	a2,12(a2)
    295c:	00f686b3          	add	a3,a3,a5
    2960:	0016e793          	ori	a5,a3,1
    2964:	00c5a623          	sw	a2,12(a1)
    2968:	00b62423          	sw	a1,8(a2)
    296c:	00f72223          	sw	a5,4(a4)
    2970:	00d70733          	add	a4,a4,a3
    2974:	00d72023          	sw	a3,0(a4)
    2978:	ef9ff06f          	j	2870 <_free_r+0xdc>
    297c:	0015f593          	andi	a1,a1,1
    2980:	00d786b3          	add	a3,a5,a3
    2984:	02059063          	bnez	a1,29a4 <_free_r+0x210>
    2988:	ff842583          	lw	a1,-8(s0)
    298c:	40b70733          	sub	a4,a4,a1
    2990:	00c72783          	lw	a5,12(a4)
    2994:	00872603          	lw	a2,8(a4)
    2998:	00b686b3          	add	a3,a3,a1
    299c:	00f62623          	sw	a5,12(a2)
    29a0:	00c7a423          	sw	a2,8(a5)
    29a4:	0016e793          	ori	a5,a3,1
    29a8:	00f72223          	sw	a5,4(a4)
    29ac:	00e52423          	sw	a4,8(a0)
    29b0:	8241a783          	lw	a5,-2012(gp) # 7384 <__malloc_trim_threshold>
    29b4:	eaf6eee3          	bltu	a3,a5,2870 <_free_r+0xdc>
    29b8:	87c1a583          	lw	a1,-1924(gp) # 73dc <__malloc_top_pad>
    29bc:	00048513          	mv	a0,s1
    29c0:	c9dff0ef          	jal	265c <_malloc_trim_r>
    29c4:	eadff06f          	j	2870 <_free_r+0xdc>
    29c8:	00d787b3          	add	a5,a5,a3
    29cc:	f5dff06f          	j	2928 <_free_r+0x194>
    29d0:	01400613          	li	a2,20
    29d4:	02d67063          	bgeu	a2,a3,29f4 <_free_r+0x260>
    29d8:	05400613          	li	a2,84
    29dc:	06d66463          	bltu	a2,a3,2a44 <_free_r+0x2b0>
    29e0:	00c7d693          	srli	a3,a5,0xc
    29e4:	06f68593          	addi	a1,a3,111
    29e8:	06e68613          	addi	a2,a3,110
    29ec:	00359593          	slli	a1,a1,0x3
    29f0:	ed5ff06f          	j	28c4 <_free_r+0x130>
    29f4:	05c68593          	addi	a1,a3,92
    29f8:	05b68613          	addi	a2,a3,91
    29fc:	00359593          	slli	a1,a1,0x3
    2a00:	ec5ff06f          	j	28c4 <_free_r+0x130>
    2a04:	00e52a23          	sw	a4,20(a0)
    2a08:	00e52823          	sw	a4,16(a0)
    2a0c:	0017e693          	ori	a3,a5,1
    2a10:	01172623          	sw	a7,12(a4)
    2a14:	01172423          	sw	a7,8(a4)
    2a18:	00d72223          	sw	a3,4(a4)
    2a1c:	00f70733          	add	a4,a4,a5
    2a20:	00f72023          	sw	a5,0(a4)
    2a24:	e4dff06f          	j	2870 <_free_r+0xdc>
    2a28:	00452803          	lw	a6,4(a0)
    2a2c:	40265613          	srai	a2,a2,0x2
    2a30:	00100793          	li	a5,1
    2a34:	00c797b3          	sll	a5,a5,a2
    2a38:	0107e7b3          	or	a5,a5,a6
    2a3c:	00f52223          	sw	a5,4(a0)
    2a40:	eb1ff06f          	j	28f0 <_free_r+0x15c>
    2a44:	15400613          	li	a2,340
    2a48:	00d66c63          	bltu	a2,a3,2a60 <_free_r+0x2cc>
    2a4c:	00f7d693          	srli	a3,a5,0xf
    2a50:	07868593          	addi	a1,a3,120
    2a54:	07768613          	addi	a2,a3,119
    2a58:	00359593          	slli	a1,a1,0x3
    2a5c:	e69ff06f          	j	28c4 <_free_r+0x130>
    2a60:	55400613          	li	a2,1364
    2a64:	00d66c63          	bltu	a2,a3,2a7c <_free_r+0x2e8>
    2a68:	0127d693          	srli	a3,a5,0x12
    2a6c:	07d68593          	addi	a1,a3,125
    2a70:	07c68613          	addi	a2,a3,124
    2a74:	00359593          	slli	a1,a1,0x3
    2a78:	e4dff06f          	j	28c4 <_free_r+0x130>
    2a7c:	3f800593          	li	a1,1016
    2a80:	07e00613          	li	a2,126
    2a84:	e41ff06f          	j	28c4 <_free_r+0x130>
    2a88:	0017e693          	ori	a3,a5,1
    2a8c:	00d72223          	sw	a3,4(a4)
    2a90:	00f62023          	sw	a5,0(a2)
    2a94:	dddff06f          	j	2870 <_free_r+0xdc>

00002a98 <_reclaim_reent>:
    2a98:	81c1a783          	lw	a5,-2020(gp) # 737c <_impure_ptr>
    2a9c:	0ca78e63          	beq	a5,a0,2b78 <_reclaim_reent+0xe0>
    2aa0:	04452583          	lw	a1,68(a0)
    2aa4:	fe010113          	addi	sp,sp,-32
    2aa8:	00912a23          	sw	s1,20(sp)
    2aac:	00112e23          	sw	ra,28(sp)
    2ab0:	00812c23          	sw	s0,24(sp)
    2ab4:	00050493          	mv	s1,a0
    2ab8:	04058863          	beqz	a1,2b08 <_reclaim_reent+0x70>
    2abc:	01212823          	sw	s2,16(sp)
    2ac0:	01312623          	sw	s3,12(sp)
    2ac4:	00000913          	li	s2,0
    2ac8:	08000993          	li	s3,128
    2acc:	012587b3          	add	a5,a1,s2
    2ad0:	0007a403          	lw	s0,0(a5)
    2ad4:	00040e63          	beqz	s0,2af0 <_reclaim_reent+0x58>
    2ad8:	00040593          	mv	a1,s0
    2adc:	00042403          	lw	s0,0(s0)
    2ae0:	00048513          	mv	a0,s1
    2ae4:	cb1ff0ef          	jal	2794 <_free_r>
    2ae8:	fe0418e3          	bnez	s0,2ad8 <_reclaim_reent+0x40>
    2aec:	0444a583          	lw	a1,68(s1)
    2af0:	00490913          	addi	s2,s2,4
    2af4:	fd391ce3          	bne	s2,s3,2acc <_reclaim_reent+0x34>
    2af8:	00048513          	mv	a0,s1
    2afc:	c99ff0ef          	jal	2794 <_free_r>
    2b00:	01012903          	lw	s2,16(sp)
    2b04:	00c12983          	lw	s3,12(sp)
    2b08:	0384a583          	lw	a1,56(s1)
    2b0c:	00058663          	beqz	a1,2b18 <_reclaim_reent+0x80>
    2b10:	00048513          	mv	a0,s1
    2b14:	c81ff0ef          	jal	2794 <_free_r>
    2b18:	0404a403          	lw	s0,64(s1)
    2b1c:	00040c63          	beqz	s0,2b34 <_reclaim_reent+0x9c>
    2b20:	00040593          	mv	a1,s0
    2b24:	00042403          	lw	s0,0(s0)
    2b28:	00048513          	mv	a0,s1
    2b2c:	c69ff0ef          	jal	2794 <_free_r>
    2b30:	fe0418e3          	bnez	s0,2b20 <_reclaim_reent+0x88>
    2b34:	04c4a583          	lw	a1,76(s1)
    2b38:	00058663          	beqz	a1,2b44 <_reclaim_reent+0xac>
    2b3c:	00048513          	mv	a0,s1
    2b40:	c55ff0ef          	jal	2794 <_free_r>
    2b44:	0344a783          	lw	a5,52(s1)
    2b48:	00078e63          	beqz	a5,2b64 <_reclaim_reent+0xcc>
    2b4c:	01812403          	lw	s0,24(sp)
    2b50:	01c12083          	lw	ra,28(sp)
    2b54:	00048513          	mv	a0,s1
    2b58:	01412483          	lw	s1,20(sp)
    2b5c:	02010113          	addi	sp,sp,32
    2b60:	00078067          	jr	a5
    2b64:	01c12083          	lw	ra,28(sp)
    2b68:	01812403          	lw	s0,24(sp)
    2b6c:	01412483          	lw	s1,20(sp)
    2b70:	02010113          	addi	sp,sp,32
    2b74:	00008067          	ret
    2b78:	00008067          	ret

00002b7c <main>:
    }
}
#endif

int main(void)
{
    2b7c:	fa010113          	addi	sp,sp,-96
    2b80:	04112e23          	sw	ra,92(sp)
    2b84:	04812c23          	sw	s0,88(sp)
    2b88:	03712e23          	sw	s7,60(sp)
    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    2b8c:	f8010737          	lui	a4,0xf8010
    2b90:	06b00693          	li	a3,107
    2b94:	00d72423          	sw	a3,8(a4) # f8010008 <__freertos_irq_stack_top+0xf8007a88>
    2b98:	f80107b7          	lui	a5,0xf8010
    2b9c:	00700093          	li	ra,7
    int rc;

    bsp_init();
    bsp_printf("\r\n-- Efinix TinyML style-transfer deployment --\r\n");
    2ba0:	00006537          	lui	a0,0x6
    2ba4:	0017a623          	sw	ra,12(a5) # f801000c <__freertos_irq_stack_top+0xf8007a8c>
    2ba8:	ea050513          	addi	a0,a0,-352 # 5ea0 <_data+0x288>
    2bac:	6d4000ef          	jal	3280 <bsp_printf>

    style_net_ctx_init(&ctx, accel, STYLE_NET_MODEL_BASE, STYLE_NET_ARENA_BASE);
    2bb0:	88818513          	addi	a0,gp,-1912 # 73e8 <ctx>
    2bb4:	048006b7          	lui	a3,0x4800
    2bb8:	04000637          	lui	a2,0x4000
    2bbc:	f81005b7          	lui	a1,0xf8100
    2bc0:	00028413          	mv	s0,t0
    2bc4:	4c1010ef          	jal	4884 <style_net_ctx_init>
     * style_net_ctx_init -- do NOT hard-code it here or the makefile
     * STYLE_NET_TIMEOUT_CYCLES= override is silently ignored. */
    /* Bring-up escape hatch: make STYLE_NET_NO_IRQ=1 sets this to 0, so the
     * accelerator runs with IRQ_EN clear and wait_done() polls STATUS.  That
     * isolates the datapath from the PLIC/IRQ plumbing entirely. */
    ctx.use_irq = STYLE_NET_USE_IRQ;
    2bc8:	88818b93          	addi	s7,gp,-1912 # 73e8 <ctx>
    2bcc:	00100313          	li	t1,1

    rc = style_net_probe(&ctx);
    2bd0:	88818513          	addi	a0,gp,-1912 # 73e8 <ctx>
    ctx.use_irq = STYLE_NET_USE_IRQ;
    2bd4:	006baa23          	sw	t1,20(s7)
    rc = style_net_probe(&ctx);
    2bd8:	4f9010ef          	jal	48d0 <style_net_probe>
    if (rc != STYLE_NET_OK) {
    2bdc:	02050e63          	beqz	a0,2c18 <main+0x9c>
        halt("accelerator probe", rc);
    2be0:	00006437          	lui	s0,0x6
    2be4:	00050593          	mv	a1,a0
    2be8:	ed440513          	addi	a0,s0,-300 # 5ed4 <_data+0x2bc>
    2bec:	04912a23          	sw	s1,84(sp)
    2bf0:	05212823          	sw	s2,80(sp)
    2bf4:	05312623          	sw	s3,76(sp)
    2bf8:	05412423          	sw	s4,72(sp)
    2bfc:	05512223          	sw	s5,68(sp)
    2c00:	05612023          	sw	s6,64(sp)
    2c04:	03812c23          	sw	s8,56(sp)
    2c08:	03912a23          	sw	s9,52(sp)
    2c0c:	03a12823          	sw	s10,48(sp)
    2c10:	03b12623          	sw	s11,44(sp)
    2c14:	131000ef          	jal	3544 <halt>
    }
    /* NOTE: the BSP bsp_printf handles %c %s %d %X %x only. A %u is not
     * recognised and its parser then swallows the rest of the format string,
     * which is why this line used to stop printing after "passes=". */
    bsp_printf("accelerator ABI 0x%x, passes=%d, lanes=%d\r\n",
               (int)accel[STYLE_NET_REG_VERSION / 4u],
    2c18:	f81003b7          	lui	t2,0xf8100
               (int)accel[STYLE_NET_REG_PASS_COUNT / 4u],
    2c1c:	f8100637          	lui	a2,0xf8100
               (int)accel[STYLE_NET_REG_VERSION / 4u],
    2c20:	0803a583          	lw	a1,128(t2) # f8100080 <__freertos_irq_stack_top+0xf80f7b00>
               (int)accel[STYLE_NET_REG_PASS_COUNT / 4u],
    2c24:	07c62603          	lw	a2,124(a2) # f810007c <__freertos_irq_stack_top+0xf80f7afc>
    bsp_printf("accelerator ABI 0x%x, passes=%d, lanes=%d\r\n",
    2c28:	00006837          	lui	a6,0x6
    2c2c:	05000693          	li	a3,80
    2c30:	ee880513          	addi	a0,a6,-280 # 5ee8 <_data+0x2d0>
    2c34:	64c000ef          	jal	3280 <bsp_printf>
    accel[STYLE_NET_REG_PASS_ID / 4u] = 17u;
    2c38:	f81005b7          	lui	a1,0xf8100
    2c3c:	00c58893          	addi	a7,a1,12 # f810000c <__freertos_irq_stack_top+0xf80f7a8c>
    2c40:	01100e13          	li	t3,17
    2c44:	01c8a023          	sw	t3,0(a7)
    if (accel[STYLE_NET_REG_PASS_ID / 4u] != 17u) {
    2c48:	0008ae83          	lw	t4,0(a7)
    2c4c:	43ce9e63          	bne	t4,t3,3088 <main+0x50c>
    2c50:	04912a23          	sw	s1,84(sp)
    2c54:	05212823          	sw	s2,80(sp)
    2c58:	05312623          	sw	s3,76(sp)
    2c5c:	05412423          	sw	s4,72(sp)
    2c60:	05512223          	sw	s5,68(sp)
    2c64:	05612023          	sw	s6,64(sp)
    2c68:	03812c23          	sw	s8,56(sp)
    2c6c:	03912a23          	sw	s9,52(sp)
    2c70:	03a12823          	sw	s10,48(sp)
    2c74:	03b12623          	sw	s11,44(sp)
               (int)style_net_pass_table[0].lanes);

    apb_readback_test();
    bsp_printf("APB register readback OK\r\n");
    2c78:	000064b7          	lui	s1,0x6
    accel[STYLE_NET_REG_PASS_ID / 4u] = 0u;
    2c7c:	0008a023          	sw	zero,0(a7)
    bsp_printf("APB register readback OK\r\n");
    2c80:	f3848513          	addi	a0,s1,-200 # 5f38 <_data+0x320>
    2c84:	5fc000ef          	jal	3280 <bsp_printf>

    /* Route the accelerator IRQ through the PLIC and enable machine
     * external interrupts. */
    style_net_irq_init(accel);
    2c88:	f8100537          	lui	a0,0xf8100
    2c8c:	3dd020ef          	jal	5868 <style_net_irq_init>
    style_net_irq_reset();
    bsp_printf("accelerator IRQ on PLIC gateway %d\r\n",
    2c90:	00006937          	lui	s2,0x6
    style_net_irq_reset();
    2c94:	3c9020ef          	jal	585c <style_net_irq_reset>
    bsp_printf("accelerator IRQ on PLIC gateway %d\r\n",
    2c98:	01000593          	li	a1,16
    2c9c:	f5490513          	addi	a0,s2,-172 # 5f54 <_data+0x33c>
    2ca0:	5e0000ef          	jal	3280 <bsp_printf>
               (int)STYLE_NET_PLIC_IRQ_ID);

    /* CLINT sanity: the scheduler timeouts (and the previous self-test)
     * depend on mtime actually ticking on this SoC. */
    {
        const uint32_t t0 = (uint32_t)style_net_time_now();
    2ca4:	37d020ef          	jal	5820 <style_net_time_now>
        volatile uint32_t spin = 0u;
        uint32_t i;

        for (i = 0u; i < 10000u; ++i) {
    2ca8:	000029b7          	lui	s3,0x2
        const uint32_t t0 = (uint32_t)style_net_time_now();
    2cac:	00050a13          	mv	s4,a0
        volatile uint32_t spin = 0u;
    2cb0:	00012e23          	sw	zero,28(sp)
        for (i = 0u; i < 10000u; ++i) {
    2cb4:	00000793          	li	a5,0
    2cb8:	71098a93          	addi	s5,s3,1808 # 2710 <_malloc_trim_r+0xb4>
            spin = spin + i;
    2cbc:	01c12b03          	lw	s6,28(sp)
        for (i = 0u; i < 10000u; ++i) {
    2cc0:	00178c13          	addi	s8,a5,1
    2cc4:	00278c93          	addi	s9,a5,2
            spin = spin + i;
    2cc8:	00fb0d33          	add	s10,s6,a5
    2ccc:	01a12e23          	sw	s10,28(sp)
    2cd0:	01c12d83          	lw	s11,28(sp)
        for (i = 0u; i < 10000u; ++i) {
    2cd4:	00378f13          	addi	t5,a5,3
    2cd8:	00478f93          	addi	t6,a5,4
            spin = spin + i;
    2cdc:	018d8733          	add	a4,s11,s8
    2ce0:	00e12e23          	sw	a4,28(sp)
    2ce4:	01c12683          	lw	a3,28(sp)
        for (i = 0u; i < 10000u; ++i) {
    2ce8:	00578093          	addi	ra,a5,5
    2cec:	00678513          	addi	a0,a5,6
            spin = spin + i;
    2cf0:	019682b3          	add	t0,a3,s9
    2cf4:	00512e23          	sw	t0,28(sp)
    2cf8:	01c12403          	lw	s0,28(sp)
        for (i = 0u; i < 10000u; ++i) {
    2cfc:	00778313          	addi	t1,a5,7
    2d00:	00878793          	addi	a5,a5,8
            spin = spin + i;
    2d04:	01e403b3          	add	t2,s0,t5
    2d08:	00712e23          	sw	t2,28(sp)
    2d0c:	01c12603          	lw	a2,28(sp)
    2d10:	01f60833          	add	a6,a2,t6
    2d14:	01012e23          	sw	a6,28(sp)
    2d18:	01c12583          	lw	a1,28(sp)
    2d1c:	001588b3          	add	a7,a1,ra
    2d20:	01112e23          	sw	a7,28(sp)
    2d24:	01c12e03          	lw	t3,28(sp)
    2d28:	00ae0eb3          	add	t4,t3,a0
    2d2c:	01d12e23          	sw	t4,28(sp)
    2d30:	01c12483          	lw	s1,28(sp)
    2d34:	00648933          	add	s2,s1,t1
    2d38:	01212e23          	sw	s2,28(sp)
        for (i = 0u; i < 10000u; ++i) {
    2d3c:	f95790e3          	bne	a5,s5,2cbc <main+0x140>
        }
        bsp_printf("CLINT mtime: %d -> %d\r\n",
                   (int)t0, (int)(uint32_t)style_net_time_now());
    2d40:	2e1020ef          	jal	5820 <style_net_time_now>
        bsp_printf("CLINT mtime: %d -> %d\r\n",
    2d44:	000069b7          	lui	s3,0x6
                   (int)t0, (int)(uint32_t)style_net_time_now());
    2d48:	00050613          	mv	a2,a0
        bsp_printf("CLINT mtime: %d -> %d\r\n",
    2d4c:	000a0593          	mv	a1,s4
    2d50:	f7c98513          	addi	a0,s3,-132 # 5f7c <_data+0x364>
    2d54:	52c000ef          	jal	3280 <bsp_printf>
    }

    bsp_printf("IRQ self-test: start\r\n");
    2d58:	00006a37          	lui	s4,0x6
    2d5c:	f94a0513          	addi	a0,s4,-108 # 5f94 <_data+0x37c>
    2d60:	520000ef          	jal	3280 <bsp_printf>
    accel[STYLE_NET_REG_CTRL / 4u] = STYLE_NET_CTRL_IRQ_EN;
    2d64:	f8100ab7          	lui	s5,0xf8100
    2d68:	00200b13          	li	s6,2
    const uint32_t before = style_net_irq_count();
    2d6c:	2e1020ef          	jal	584c <style_net_irq_count>
    accel[STYLE_NET_REG_CTRL / 4u] =
    2d70:	01200c93          	li	s9,18
    accel[STYLE_NET_REG_CTRL / 4u] = STYLE_NET_CTRL_IRQ_EN;
    2d74:	016aa023          	sw	s6,0(s5) # f8100000 <__freertos_irq_stack_top+0xf80f7a80>
    status = accel[STYLE_NET_REG_STATUS / 4u];
    2d78:	f8100c37          	lui	s8,0xf8100
    accel[STYLE_NET_REG_CTRL / 4u] =
    2d7c:	019aa023          	sw	s9,0(s5)
    status = accel[STYLE_NET_REG_STATUS / 4u];
    2d80:	004c2d03          	lw	s10,4(s8) # f8100004 <__freertos_irq_stack_top+0xf80f7a84>
    const uint32_t before = style_net_irq_count();
    2d84:	00050d93          	mv	s11,a0
    if ((status & STYLE_NET_STATUS_DONE) == 0u) {
    2d88:	020004b7          	lui	s1,0x2000
    2d8c:	002d7f13          	andi	t5,s10,2
    2d90:	460f0663          	beqz	t5,31fc <main+0x680>
    while (style_net_irq_count() == before) {
    2d94:	2b9020ef          	jal	584c <style_net_irq_count>
    2d98:	44ad9063          	bne	s11,a0,31d8 <main+0x65c>
    2d9c:	2b1020ef          	jal	584c <style_net_irq_count>
    2da0:	42ad9c63          	bne	s11,a0,31d8 <main+0x65c>
    2da4:	2a9020ef          	jal	584c <style_net_irq_count>
    2da8:	42ad9863          	bne	s11,a0,31d8 <main+0x65c>
    2dac:	2a1020ef          	jal	584c <style_net_irq_count>
    2db0:	42ad9463          	bne	s11,a0,31d8 <main+0x65c>
    2db4:	299020ef          	jal	584c <style_net_irq_count>
    2db8:	42ad9063          	bne	s11,a0,31d8 <main+0x65c>
    2dbc:	291020ef          	jal	584c <style_net_irq_count>
    2dc0:	40ad9c63          	bne	s11,a0,31d8 <main+0x65c>
    2dc4:	289020ef          	jal	584c <style_net_irq_count>
    2dc8:	40ad9863          	bne	s11,a0,31d8 <main+0x65c>
    2dcc:	281020ef          	jal	584c <style_net_irq_count>
    2dd0:	40ad9463          	bne	s11,a0,31d8 <main+0x65c>
        if (--guard == 0u) {
    2dd4:	ff848493          	addi	s1,s1,-8 # 1fffff8 <__freertos_irq_stack_top+0x1ff7a78>
    2dd8:	fa049ee3          	bnez	s1,2d94 <main+0x218>
        break;
    case -2:
        bsp_printf("IRQ self-test SKIP: bitstream has no CTRL_FORCE_DONE\r\n");
        break;
    default:
        bsp_printf("IRQ self-test FAIL: no interrupt (check PLIC wiring)\r\n");
    2ddc:	00006737          	lui	a4,0x6
    2de0:	29070513          	addi	a0,a4,656 # 6290 <_data+0x678>
    2de4:	49c000ef          	jal	3280 <bsp_printf>

#ifdef STYLE_NET_MULTI_STYLE
    {
        unsigned i;

        style_multistyle_prepare();
    2de8:	3e0010ef          	jal	41c8 <style_multistyle_prepare>

        for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
    2dec:	00006537          	lui	a0,0x6
    2df0:	5f450d13          	addi	s10,a0,1524 # 65f4 <style_multistyle_entries>
    2df4:	5f450a93          	addi	s5,a0,1524
    2df8:	00000a13          	li	s4,0
            if (style_multistyle_verify(entry) != 0) {
                bsp_printf("ERROR: model %s @0x%x hash mismatch\r\n",
                           entry->name, (unsigned)entry->model_base);
                halt("multi-style model verify", STYLE_NET_ERR_BLOB);
            }
            bsp_printf("style %d: %s @0x%x OK (%d bytes)\r\n",
    2dfc:	000069b7          	lui	s3,0x6
        for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
    2e00:	00300913          	li	s2,3
            if (style_multistyle_verify(entry) != 0) {
    2e04:	000a8513          	mv	a0,s5
    2e08:	230010ef          	jal	4038 <style_multistyle_verify>
    2e0c:	44051263          	bnez	a0,3250 <main+0x6d4>
            bsp_printf("style %d: %s @0x%x OK (%d bytes)\r\n",
    2e10:	010aa703          	lw	a4,16(s5)
    2e14:	008aa683          	lw	a3,8(s5)
    2e18:	004aa603          	lw	a2,4(s5)
                       (int)(i + 1u), entry->name,
    2e1c:	001a0a13          	addi	s4,s4,1
            bsp_printf("style %d: %s @0x%x OK (%d bytes)\r\n",
    2e20:	000a0593          	mv	a1,s4
    2e24:	02898513          	addi	a0,s3,40 # 6028 <_data+0x410>
    2e28:	458000ef          	jal	3280 <bsp_printf>
        for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
    2e2c:	018a8a93          	addi	s5,s5,24
    2e30:	fd2a1ae3          	bne	s4,s2,2e04 <main+0x288>
    ctx.model_base = active_style->model_base;
    2e34:	008d2603          	lw	a2,8(s10)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    2e38:	004d2583          	lw	a1,4(s10)
    2e3c:	00006db7          	lui	s11,0x6
    2e40:	dbcd8513          	addi	a0,s11,-580 # 5dbc <_data+0x1a4>
    ctx.model_base = active_style->model_base;
    2e44:	00cba223          	sw	a2,4(s7)
    active_style_index = index;
    2e48:	8401a023          	sw	zero,-1984(gp) # 73a0 <active_style_index>
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    2e4c:	434000ef          	jal	3280 <bsp_printf>
    active_style_strength = value;
    2e50:	0ff00293          	li	t0,255
    2e54:	8251ac23          	sw	t0,-1992(gp) # 7398 <active_style_strength>
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    2e58:	f8100337          	lui	t1,0xf8100
    2e5c:	0a532223          	sw	t0,164(t1) # f81000a4 <__freertos_irq_stack_top+0xf80f7b24>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    2e60:	f81003b7          	lui	t2,0xf8100
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    2e64:	00006837          	lui	a6,0x6
    active_display_mode = mode;
    2e68:	8341ae23          	sw	s4,-1988(gp) # 739c <active_display_mode>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    2e6c:	d6080513          	addi	a0,a6,-672 # 5d60 <_data+0x148>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    2e70:	0b43a023          	sw	s4,160(t2) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    2e74:	0ff00593          	li	a1,255
    2e78:	408000ef          	jal	3280 <bsp_printf>
                       (unsigned)entry->model_base, (int)entry->model_bytes);
        }
        apply_style(0u);
        set_style_strength(255u, 0);
        set_display_mode(STYLE_NET_DISPLAY_MIX);
        bsp_printf("style hot-switch: UART 1=future 2=vangogh 3=cubism\r\n");
    2e7c:	000065b7          	lui	a1,0x6
    2e80:	04c58513          	addi	a0,a1,76 # 604c <_data+0x434>
    2e84:	3fc000ef          	jal	3280 <bsp_printf>
        bsp_printf("display: default=mix; KEY1=styled/split; UART 0=split 5=styled 6=mix\r\n");
    2e88:	000068b7          	lui	a7,0x6
    2e8c:	08488513          	addi	a0,a7,132 # 6084 <_data+0x46c>
    2e90:	3f0000ef          	jal	3280 <bsp_printf>
        bsp_printf("intensity: default=255; KEY2=+ KEY3=-; UART +/- step 16\r\n");
    2e94:	00006e37          	lui	t3,0x6
    2e98:	0cce0513          	addi	a0,t3,204 # 60cc <_data+0x4b4>
    2e9c:	3e4000ef          	jal	3280 <bsp_printf>
        {
            const uint32_t key_status =
    2ea0:	f8100eb7          	lui	t4,0xf8100
    2ea4:	098eac03          	lw	s8,152(t4) # f8100098 <__freertos_irq_stack_top+0xf80f7b18>
                accel[STYLE_NET_REG_KEY0_STATUS / 4u];
            const uint32_t key12_status =
    2ea8:	f8100cb7          	lui	s9,0xf8100
    2eac:	09cca483          	lw	s1,156(s9) # f810009c <__freertos_irq_stack_top+0xf80f7b1c>
                accel[STYLE_NET_REG_KEY12_STATUS / 4u];
            bsp_printf("key0: GPIOL_07 level=%d, cycles styles\r\n",
    2eb0:	001c5f13          	srli	t5,s8,0x1
    2eb4:	00006437          	lui	s0,0x6
    2eb8:	001f7593          	andi	a1,t5,1
    2ebc:	10840513          	addi	a0,s0,264 # 6108 <_data+0x4f0>
    2ec0:	3c0000ef          	jal	3280 <bsp_printf>
                       (int)((key_status & STYLE_NET_KEY0_LEVEL) != 0u));
            last_key1_level =
                (key12_status & STYLE_NET_KEY1_LEVEL) != 0u;
    2ec4:	0014df93          	srli	t6,s1,0x1
            last_key2_level =
                (key12_status & STYLE_NET_KEY2_LEVEL) != 0u;
    2ec8:	0034d713          	srli	a4,s1,0x3
            last_key3_level =
                (key12_status & STYLE_NET_KEY3_LEVEL) != 0u;
    2ecc:	0054d693          	srli	a3,s1,0x5
            bsp_printf("key1: GPIOR_22 level=%d; key2: GPIOR_21 level=%d; key3: GPIOL_03 level=%d\r\n",
    2ed0:	00006537          	lui	a0,0x6
                (key12_status & STYLE_NET_KEY1_LEVEL) != 0u;
    2ed4:	001ff593          	andi	a1,t6,1
                (key12_status & STYLE_NET_KEY2_LEVEL) != 0u;
    2ed8:	00177613          	andi	a2,a4,1
                (key12_status & STYLE_NET_KEY3_LEVEL) != 0u;
    2edc:	0016f693          	andi	a3,a3,1
            bsp_printf("key1: GPIOR_22 level=%d; key2: GPIOR_21 level=%d; key3: GPIOL_03 level=%d\r\n",
    2ee0:	13450513          	addi	a0,a0,308 # 6134 <_data+0x51c>
                (key12_status & STYLE_NET_KEY3_LEVEL) != 0u;
    2ee4:	80d1a823          	sw	a3,-2032(gp) # 7370 <last_key3_level>
                (key12_status & STYLE_NET_KEY1_LEVEL) != 0u;
    2ee8:	80b1ac23          	sw	a1,-2024(gp) # 7378 <last_key1_level>
                (key12_status & STYLE_NET_KEY2_LEVEL) != 0u;
    2eec:	80c1aa23          	sw	a2,-2028(gp) # 7374 <last_key2_level>
            bsp_printf("key1: GPIOR_22 level=%d; key2: GPIOR_21 level=%d; key3: GPIOL_03 level=%d\r\n",
    2ef0:	390000ef          	jal	3280 <bsp_printf>
    }
    bsp_printf("model loaded: %d bytes -> 0x%x\r\n",
               (int)style_model_blob_len,
               (unsigned)STYLE_NET_MODEL_BASE);
#endif
    bsp_printf("arena: 0x%x, %d bytes\r\n",
    2ef4:	000062b7          	lui	t0,0x6
    2ef8:	0007eab7          	lui	s5,0x7e
    2efc:	18028513          	addi	a0,t0,384 # 6180 <_data+0x568>
    2f00:	200a8613          	addi	a2,s5,512 # 7e200 <__freertos_irq_stack_top+0x75c80>
    2f04:	048005b7          	lui	a1,0x4800
    2f08:	378000ef          	jal	3280 <bsp_printf>
               (unsigned)STYLE_NET_ARENA_BASE,
               (int)STYLE_NET_ARENA_SIZE);

    bsp_printf("pass table: first flags=0x%x last flags=0x%x\r\n",
    2f0c:	00006337          	lui	t1,0x6
    2f10:	0a200613          	li	a2,162
    2f14:	10500593          	li	a1,261
    2f18:	19830513          	addi	a0,t1,408 # 6198 <_data+0x580>
    2f1c:	364000ef          	jal	3280 <bsp_printf>
#endif

#ifdef STYLE_NET_FIRST_PASS
        first = (uint32_t)STYLE_NET_FIRST_PASS;
#endif
        if (rcfg[0] == STYLE_NET_RUNCFG_MAGIC) {
    2f20:	047007b7          	lui	a5,0x4700
    2f24:	0007a383          	lw	t2,0(a5) # 4700000 <__freertos_irq_stack_top+0x46f7a80>
    2f28:	5a4c3637          	lui	a2,0x5a4c3
    2f2c:	55160813          	addi	a6,a2,1361 # 5a4c3551 <__freertos_irq_stack_top+0x5a4bafd1>
    2f30:	2f038263          	beq	t2,a6,3214 <main+0x698>
    bsp_printf("stream: waiting for complete q_in frames\r\n");
    2f34:	00006f37          	lui	t5,0x6
    2f38:	1ecf0513          	addi	a0,t5,492 # 61ec <_data+0x5d4>
    2f3c:	344000ef          	jal	3280 <bsp_printf>
    uint32_t count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    2f40:	f81004b7          	lui	s1,0xf8100
            if ((style_net_time_now() - t0) >=
    2f44:	1dcd6fb7          	lui	t6,0x1dcd6
    const uint32_t status = accel[STYLE_NET_REG_KEY0_STATUS / 4u];
    2f48:	f8100737          	lui	a4,0xf8100
    uint32_t count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    2f4c:	08848993          	addi	s3,s1,136 # f8100088 <__freertos_irq_stack_top+0xf80f7b08>
            if ((style_net_time_now() - t0) >=
    2f50:	4fff8a93          	addi	s5,t6,1279 # 1dcd64ff <__freertos_irq_stack_top+0x1dccdf7f>
    const uint32_t status = accel[STYLE_NET_REG_KEY0_STATUS / 4u];
    2f54:	09870a13          	addi	s4,a4,152 # f8100098 <__freertos_irq_stack_top+0xf80f7b18>
    const uint64_t t0 = style_net_time_now();
    2f58:	0c9020ef          	jal	5820 <style_net_time_now>
    uint32_t count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    2f5c:	0009a383          	lw	t2,0(s3)
    uint32_t seen = 0u;
    2f60:	00000413          	li	s0,0
    uint32_t bank = 1u;   /* display starts on bank 0; render the first frame to bank 1 */
    2f64:	00100c93          	li	s9,1
    uint32_t frames = 0u;
    2f68:	00000c13          	li	s8,0
    const uint64_t t0 = style_net_time_now();
    2f6c:	00050493          	mv	s1,a0
    2f70:	00058913          	mv	s2,a1
    if (*seen == 0u) {
    2f74:	0c041863          	bnez	s0,3044 <main+0x4c8>
        while (count == 0u) {
    2f78:	10039463          	bnez	t2,3080 <main+0x504>
            if ((style_net_time_now() - t0) >=
    2f7c:	0a5020ef          	jal	5820 <style_net_time_now>
    2f80:	409506b3          	sub	a3,a0,s1
    2f84:	00d53533          	sltu	a0,a0,a3
    2f88:	412582b3          	sub	t0,a1,s2
    2f8c:	16a29a63          	bne	t0,a0,3100 <main+0x584>
    2f90:	16dae863          	bltu	s5,a3,3100 <main+0x584>
    poll_style_switch();
    2f94:	079000ef          	jal	380c <poll_style_switch>
    const uint32_t status = accel[STYLE_NET_REG_KEY0_STATUS / 4u];
    2f98:	000a2303          	lw	t1,0(s4)
    if ((status & STYLE_NET_KEY0_EVENT) != 0u) {
    2f9c:	00137793          	andi	a5,t1,1
    2fa0:	0e079c63          	bnez	a5,3098 <main+0x51c>
    poll_display_switch();
    2fa4:	5dc000ef          	jal	3580 <poll_display_switch>
            style_net_idle();
    2fa8:	09d020ef          	jal	5844 <style_net_idle>
            count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    2fac:	0009a403          	lw	s0,0(s3)
        while (count == 0u) {
    2fb0:	fc0406e3          	beqz	s0,2f7c <main+0x400>
    poll_style_switch();
    2fb4:	059000ef          	jal	380c <poll_style_switch>
    const uint32_t status = accel[STYLE_NET_REG_KEY0_STATUS / 4u];
    2fb8:	000a2483          	lw	s1,0(s4)
    if ((status & STYLE_NET_KEY0_EVENT) != 0u) {
    2fbc:	0014f913          	andi	s2,s1,1
    2fc0:	1c091a63          	bnez	s2,3194 <main+0x618>
    poll_display_switch();
    2fc4:	5bc000ef          	jal	3580 <poll_display_switch>
                                   : STYLE_NET_QOUT_BANK0_ADDR;
    2fc8:	1a0c9863          	bnez	s9,3178 <main+0x5fc>
        ctx.output_override = bank ? STYLE_NET_QOUT_BANK1_ADDR
    2fcc:	04ac9537          	lui	a0,0x4ac9
    2fd0:	80050393          	addi	t2,a0,-2048 # 4ac8800 <__freertos_irq_stack_top+0x4ac0280>
        rc = style_net_run_frame(&ctx);
    2fd4:	88818513          	addi	a0,gp,-1912 # 73e8 <ctx>
        ctx.output_override = bank ? STYLE_NET_QOUT_BANK1_ADDR
    2fd8:	027ba423          	sw	t2,40(s7)
        rc = style_net_run_frame(&ctx);
    2fdc:	664020ef          	jal	5640 <style_net_run_frame>
        if (rc != STYLE_NET_OK) {
    2fe0:	12051263          	bnez	a0,3104 <main+0x588>
            bank ? STYLE_NET_VIDEO_CTRL_QOUT_BANK : 0u;
    2fe4:	00000593          	li	a1,0
        accel[STYLE_NET_REG_VIDEO_CTRL / 4u] =
    2fe8:	f81008b7          	lui	a7,0xf8100
    2fec:	08b8a623          	sw	a1,140(a7) # f810008c <__freertos_irq_stack_top+0xf80f7b0c>
        if ((accel[STYLE_NET_REG_VIDEO_CTRL / 4u] &
    2ff0:	08c8ae03          	lw	t3,140(a7)
    2ff4:	001e7e93          	andi	t4,t3,1
    2ff8:	21d59a63          	bne	a1,t4,320c <main+0x690>
        frames++;
    2ffc:	001c0c13          	addi	s8,s8,1
        if (frames == 1u ||
    3000:	00100913          	li	s2,1
    3004:	012c0663          	beq	s8,s2,3010 <main+0x494>
            (frames & (uint32_t)STYLE_NET_STREAM_REPORT_MASK) == 0u) {
    3008:	007c7f13          	andi	t5,s8,7
        if (frames == 1u ||
    300c:	020f1063          	bnez	t5,302c <main+0x4b0>
            bsp_printf("stream frame %d: qin=%d cycles=%d bank=%d\r\n",
    3010:	020ba683          	lw	a3,32(s7)
    3014:	00006fb7          	lui	t6,0x6
    3018:	000c8713          	mv	a4,s9
    301c:	00040613          	mv	a2,s0
    3020:	000c0593          	mv	a1,s8
    3024:	22cf8513          	addi	a0,t6,556 # 622c <_data+0x614>
    3028:	258000ef          	jal	3280 <bsp_printf>
    const uint64_t t0 = style_net_time_now();
    302c:	7f4020ef          	jal	5820 <style_net_time_now>
    uint32_t count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    3030:	0009a383          	lw	t2,0(s3)
        bank ^= 1u;
    3034:	001ccc93          	xori	s9,s9,1
    const uint64_t t0 = style_net_time_now();
    3038:	00050493          	mv	s1,a0
    303c:	00058913          	mv	s2,a1
    if (*seen == 0u) {
    3040:	f2040ce3          	beqz	s0,2f78 <main+0x3fc>
        while (count == *seen) {
    3044:	02839e63          	bne	t2,s0,3080 <main+0x504>
            if ((style_net_time_now() - t0) >=
    3048:	7d8020ef          	jal	5820 <style_net_time_now>
    304c:	409506b3          	sub	a3,a0,s1
    3050:	00d53533          	sltu	a0,a0,a3
    3054:	412582b3          	sub	t0,a1,s2
    3058:	0aa29463          	bne	t0,a0,3100 <main+0x584>
    305c:	0adae263          	bltu	s5,a3,3100 <main+0x584>
    poll_style_switch();
    3060:	7ac000ef          	jal	380c <poll_style_switch>
    const uint32_t status = accel[STYLE_NET_REG_KEY0_STATUS / 4u];
    3064:	000a2303          	lw	t1,0(s4)
    if ((status & STYLE_NET_KEY0_EVENT) != 0u) {
    3068:	00137793          	andi	a5,t1,1
    306c:	0a079463          	bnez	a5,3114 <main+0x598>
    poll_display_switch();
    3070:	510000ef          	jal	3580 <poll_display_switch>
            style_net_idle();
    3074:	7d0020ef          	jal	5844 <style_net_idle>
            count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    3078:	0009a383          	lw	t2,0(s3)
        while (count == *seen) {
    307c:	fc8386e3          	beq	t2,s0,3048 <main+0x4cc>
    uint32_t count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    3080:	00038413          	mv	s0,t2
    3084:	f31ff06f          	j	2fb4 <main+0x438>
        bsp_printf("ERROR: APB write/readback failed\r\n");
    3088:	00006db7          	lui	s11,0x6
    308c:	f14d8513          	addi	a0,s11,-236 # 5f14 <_data+0x2fc>
    3090:	1f0000ef          	jal	3280 <bsp_printf>
        while (1) {
    3094:	0000006f          	j	3094 <main+0x518>
            (active_style_index + 1u) % STYLE_MULTISTYLE_COUNT;
    3098:	8401a383          	lw	t2,-1984(gp) # 73a0 <active_style_index>
        const unsigned next =
    309c:	00300093          	li	ra,3
        bsp_printf("key0: next style\r\n");
    30a0:	00006637          	lui	a2,0x6
            (active_style_index + 1u) % STYLE_MULTISTYLE_COUNT;
    30a4:	00138813          	addi	a6,t2,1
        const unsigned next =
    30a8:	02187433          	remu	s0,a6,ra
        bsp_printf("key0: next style\r\n");
    30ac:	21860513          	addi	a0,a2,536 # 6218 <_data+0x600>
    30b0:	1d0000ef          	jal	3280 <bsp_printf>
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    30b4:	dbcd8513          	addi	a0,s11,-580
    ctx.model_base = active_style->model_base;
    30b8:	00141593          	slli	a1,s0,0x1
    30bc:	008588b3          	add	a7,a1,s0
    30c0:	00389e13          	slli	t3,a7,0x3
    30c4:	01cd0eb3          	add	t4,s10,t3
    30c8:	008ea603          	lw	a2,8(t4)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    30cc:	004ea583          	lw	a1,4(t4)
    active_style_index = index;
    30d0:	8481a023          	sw	s0,-1984(gp) # 73a0 <active_style_index>
    ctx.model_base = active_style->model_base;
    30d4:	00cba223          	sw	a2,4(s7)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    30d8:	1a8000ef          	jal	3280 <bsp_printf>
    poll_display_switch();
    30dc:	4a4000ef          	jal	3580 <poll_display_switch>
            style_net_idle();
    30e0:	764020ef          	jal	5844 <style_net_idle>
            count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    30e4:	0009a403          	lw	s0,0(s3)
        while (count == 0u) {
    30e8:	ec0416e3          	bnez	s0,2fb4 <main+0x438>
            if ((style_net_time_now() - t0) >=
    30ec:	734020ef          	jal	5820 <style_net_time_now>
    30f0:	409506b3          	sub	a3,a0,s1
    30f4:	00d53533          	sltu	a0,a0,a3
    30f8:	412582b3          	sub	t0,a1,s2
    30fc:	e8a28ae3          	beq	t0,a0,2f90 <main+0x414>
            return rc;
    3100:	ffd00513          	li	a0,-3
#else
        rc = style_net_run_passes_from(&ctx, first, count);
#endif
    }
    if (rc != STYLE_NET_OK) {
        halt("run frame", rc);
    3104:	00006bb7          	lui	s7,0x6
    3108:	00050593          	mv	a1,a0
    310c:	258b8513          	addi	a0,s7,600 # 6258 <_data+0x640>
    3110:	434000ef          	jal	3544 <halt>
            (active_style_index + 1u) % STYLE_MULTISTYLE_COUNT;
    3114:	8401a603          	lw	a2,-1984(gp) # 73a0 <active_style_index>
        const unsigned next =
    3118:	00300593          	li	a1,3
        bsp_printf("key0: next style\r\n");
    311c:	00006837          	lui	a6,0x6
            (active_style_index + 1u) % STYLE_MULTISTYLE_COUNT;
    3120:	00160093          	addi	ra,a2,1
        const unsigned next =
    3124:	02b0f8b3          	remu	a7,ra,a1
        bsp_printf("key0: next style\r\n");
    3128:	21880513          	addi	a0,a6,536 # 6218 <_data+0x600>
        const unsigned next =
    312c:	01112623          	sw	a7,12(sp)
        bsp_printf("key0: next style\r\n");
    3130:	150000ef          	jal	3280 <bsp_printf>
    ctx.model_base = active_style->model_base;
    3134:	00c12e03          	lw	t3,12(sp)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3138:	dbcd8513          	addi	a0,s11,-580
    ctx.model_base = active_style->model_base;
    313c:	001e1e93          	slli	t4,t3,0x1
    3140:	01ce8f33          	add	t5,t4,t3
    3144:	003f1f93          	slli	t6,t5,0x3
    3148:	01fd0733          	add	a4,s10,t6
    314c:	00872603          	lw	a2,8(a4)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3150:	00472583          	lw	a1,4(a4)
    active_style_index = index;
    3154:	85c1a023          	sw	t3,-1984(gp) # 73a0 <active_style_index>
    ctx.model_base = active_style->model_base;
    3158:	00cba223          	sw	a2,4(s7)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    315c:	124000ef          	jal	3280 <bsp_printf>
    poll_display_switch();
    3160:	420000ef          	jal	3580 <poll_display_switch>
            style_net_idle();
    3164:	6e0020ef          	jal	5844 <style_net_idle>
            count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    3168:	0009a383          	lw	t2,0(s3)
        while (count == *seen) {
    316c:	ec838ee3          	beq	t2,s0,3048 <main+0x4cc>
    uint32_t count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
    3170:	00038413          	mv	s0,t2
    3174:	e41ff06f          	j	2fb4 <main+0x438>
        ctx.output_override = bank ? STYLE_NET_QOUT_BANK1_ADDR
    3178:	04b200b7          	lui	ra,0x4b20
        rc = style_net_run_frame(&ctx);
    317c:	88818513          	addi	a0,gp,-1912 # 73e8 <ctx>
        ctx.output_override = bank ? STYLE_NET_QOUT_BANK1_ADDR
    3180:	021ba423          	sw	ra,40(s7)
        rc = style_net_run_frame(&ctx);
    3184:	4bc020ef          	jal	5640 <style_net_run_frame>
        if (rc != STYLE_NET_OK) {
    3188:	f6051ee3          	bnez	a0,3104 <main+0x588>
            bank ? STYLE_NET_VIDEO_CTRL_QOUT_BANK : 0u;
    318c:	000c8593          	mv	a1,s9
    3190:	e59ff06f          	j	2fe8 <main+0x46c>
            (active_style_index + 1u) % STYLE_MULTISTYLE_COUNT;
    3194:	8401af03          	lw	t5,-1984(gp) # 73a0 <active_style_index>
        const unsigned next =
    3198:	00300693          	li	a3,3
        bsp_printf("key0: next style\r\n");
    319c:	00006fb7          	lui	t6,0x6
            (active_style_index + 1u) % STYLE_MULTISTYLE_COUNT;
    31a0:	001f0713          	addi	a4,t5,1
        const unsigned next =
    31a4:	02d774b3          	remu	s1,a4,a3
        bsp_printf("key0: next style\r\n");
    31a8:	218f8513          	addi	a0,t6,536 # 6218 <_data+0x600>
    31ac:	0d4000ef          	jal	3280 <bsp_printf>
    ctx.model_base = active_style->model_base;
    31b0:	01800293          	li	t0,24
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    31b4:	dbcd8513          	addi	a0,s11,-580
    ctx.model_base = active_style->model_base;
    31b8:	02548333          	mul	t1,s1,t0
    active_style_index = index;
    31bc:	8491a023          	sw	s1,-1984(gp) # 73a0 <active_style_index>
    ctx.model_base = active_style->model_base;
    31c0:	006d07b3          	add	a5,s10,t1
    31c4:	0087a603          	lw	a2,8(a5)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    31c8:	0047a583          	lw	a1,4(a5)
    ctx.model_base = active_style->model_base;
    31cc:	00cba223          	sw	a2,4(s7)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    31d0:	0b0000ef          	jal	3280 <bsp_printf>
}
    31d4:	df1ff06f          	j	2fc4 <main+0x448>
                   (int)style_net_irq_count(),
    31d8:	674020ef          	jal	584c <style_net_irq_count>
    31dc:	00050413          	mv	s0,a0
                   (unsigned)style_net_irq_status());
    31e0:	674020ef          	jal	5854 <style_net_irq_status>
        bsp_printf("IRQ self-test PASS: count=%d status=0x%x\r\n",
    31e4:	00006fb7          	lui	t6,0x6
                   (unsigned)style_net_irq_status());
    31e8:	00050613          	mv	a2,a0
        bsp_printf("IRQ self-test PASS: count=%d status=0x%x\r\n",
    31ec:	00040593          	mv	a1,s0
    31f0:	264f8513          	addi	a0,t6,612 # 6264 <_data+0x64c>
    31f4:	08c000ef          	jal	3280 <bsp_printf>
        break;
    31f8:	bf1ff06f          	j	2de8 <main+0x26c>
        bsp_printf("IRQ self-test SKIP: bitstream has no CTRL_FORCE_DONE\r\n");
    31fc:	000066b7          	lui	a3,0x6
    3200:	fac68513          	addi	a0,a3,-84 # 5fac <_data+0x394>
    3204:	07c000ef          	jal	3280 <bsp_printf>
        break;
    3208:	be1ff06f          	j	2de8 <main+0x26c>
            return STYLE_NET_ERR_ABI;
    320c:	ffb00513          	li	a0,-5
    3210:	ef5ff06f          	j	3104 <main+0x588>
            first = rcfg[1] & 0xFFFFu;
    3214:	047000b7          	lui	ra,0x4700
            count = rcfg[2] & 0xFFFFu;
    3218:	047005b7          	lui	a1,0x4700
            first = rcfg[1] & 0xFFFFu;
    321c:	0040a883          	lw	a7,4(ra) # 4700004 <__freertos_irq_stack_top+0x46f7a84>
            count = rcfg[2] & 0xFFFFu;
    3220:	0085ae03          	lw	t3,8(a1) # 4700008 <__freertos_irq_stack_top+0x46f7a88>
    3224:	010e1e93          	slli	t4,t3,0x10
    3228:	010ed693          	srli	a3,t4,0x10
            bsp_printf("run cfg @0x%x: first=%d count=%d\r\n",
    322c:	00069463          	bnez	a3,3234 <main+0x6b8>
    3230:	00100693          	li	a3,1
    3234:	01089c13          	slli	s8,a7,0x10
    3238:	00006cb7          	lui	s9,0x6
    323c:	010c5613          	srli	a2,s8,0x10
    3240:	047005b7          	lui	a1,0x4700
    3244:	1c8c8513          	addi	a0,s9,456 # 61c8 <_data+0x5b0>
    3248:	038000ef          	jal	3280 <bsp_printf>
    324c:	ce9ff06f          	j	2f34 <main+0x3b8>
                           entry->name, (unsigned)entry->model_base);
    3250:	01800993          	li	s3,24
    3254:	033a0a33          	mul	s4,s4,s3
                bsp_printf("ERROR: model %s @0x%x hash mismatch\r\n",
    3258:	00006ab7          	lui	s5,0x6
    325c:	fe4a8513          	addi	a0,s5,-28 # 5fe4 <_data+0x3cc>
                           entry->name, (unsigned)entry->model_base);
    3260:	014d0b33          	add	s6,s10,s4
                bsp_printf("ERROR: model %s @0x%x hash mismatch\r\n",
    3264:	004b2583          	lw	a1,4(s6)
    3268:	008b2603          	lw	a2,8(s6)
                halt("multi-style model verify", STYLE_NET_ERR_BLOB);
    326c:	00006d37          	lui	s10,0x6
                bsp_printf("ERROR: model %s @0x%x hash mismatch\r\n",
    3270:	010000ef          	jal	3280 <bsp_printf>
                halt("multi-style model verify", STYLE_NET_ERR_BLOB);
    3274:	ff900593          	li	a1,-7
    3278:	00cd0513          	addi	a0,s10,12 # 600c <_data+0x3f4>
    327c:	2c8000ef          	jal	3544 <halt>

00003280 <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    3280:	fa010113          	addi	sp,sp,-96
        int i;
        va_list ap;

        va_start(ap, format);

        for (i = 0; format[i]; i++)
    3284:	00054f83          	lbu	t6,0(a0)
    {
    3288:	04f12a23          	sw	a5,84(sp)
        va_start(ap, format);
    328c:	04410793          	addi	a5,sp,68
    {
    3290:	04b12223          	sw	a1,68(sp)
    3294:	04c12423          	sw	a2,72(sp)
    3298:	04d12623          	sw	a3,76(sp)
    329c:	04e12823          	sw	a4,80(sp)
    32a0:	05012c23          	sw	a6,88(sp)
    32a4:	05112e23          	sw	a7,92(sp)
        va_start(ap, format);
    32a8:	00f12623          	sw	a5,12(sp)
        for (i = 0; format[i]; i++)
    32ac:	040f8a63          	beqz	t6,3300 <bsp_printf+0x80>
        return *((volatile u32*) address);
    32b0:	f8010737          	lui	a4,0xf8010
    32b4:	00006eb7          	lui	t4,0x6
    32b8:	02812e23          	sw	s0,60(sp)
    32bc:	00000613          	li	a2,0
            if (format[i] == '%') {
    32c0:	02500893          	li	a7,37
    32c4:	02000f13          	li	t5,32
    32c8:	3bce8e93          	addi	t4,t4,956 # 63bc <_data+0x7a4>
    32cc:	f8010e37          	lui	t3,0xf8010
    32d0:	00470713          	addi	a4,a4,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    32d4:	031f8a63          	beq	t6,a7,3308 <bsp_printf+0x88>
    32d8:	00072283          	lw	t0,0(a4)
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
        while(uart_writeAvailability(reg) == 0);
    32dc:	0102d693          	srli	a3,t0,0x10
    32e0:	0ff6f393          	zext.b	t2,a3
    32e4:	fe038ae3          	beqz	t2,32d8 <bsp_printf+0x58>
        *((volatile u32*) address) = data;
    32e8:	01fe2023          	sw	t6,0(t3) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        for (i = 0; format[i]; i++)
    32ec:	00160613          	addi	a2,a2,1
    32f0:	00c50433          	add	s0,a0,a2
    32f4:	00044f83          	lbu	t6,0(s0)
    32f8:	fc0f9ee3          	bnez	t6,32d4 <bsp_printf+0x54>
    32fc:	03c12403          	lw	s0,60(sp)
                }
            } else
                bsp_printf_c(format[i]);

        va_end(ap);
    }
    3300:	06010113          	addi	sp,sp,96
    3304:	00008067          	ret
                while (format[++i]) {
    3308:	00160613          	addi	a2,a2,1
    330c:	00c50333          	add	t1,a0,a2
    3310:	00034403          	lbu	s0,0(t1)
    3314:	fc040ce3          	beqz	s0,32ec <bsp_printf+0x6c>
                    if (format[i] == 'c') {
    3318:	fa840593          	addi	a1,s0,-88
    331c:	0ff5f813          	zext.b	a6,a1
    3320:	ff0f64e3          	bltu	t5,a6,3308 <bsp_printf+0x88>
    3324:	00281f93          	slli	t6,a6,0x2
    3328:	01df87b3          	add	a5,t6,t4
    332c:	0007a683          	lw	a3,0(a5)
    3330:	00068067          	jr	a3
                        bsp_printf_x(va_arg(ap,int));
    3334:	00c12283          	lw	t0,12(sp)
        return *((volatile u32*) address);
    3338:	f8010337          	lui	t1,0xf8010
    333c:	000065b7          	lui	a1,0x6
    3340:	00428393          	addi	t2,t0,4
        bsp_printHex_lower(val);
    3344:	0002a403          	lw	s0,0(t0)
                        bsp_printf_x(va_arg(ap,int));
    3348:	00712623          	sw	t2,12(sp)
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    334c:	01c00813          	li	a6,28
    3350:	c6458f93          	addi	t6,a1,-924 # 5c64 <_data+0x4c>
    3354:	f80103b7          	lui	t2,0xf8010
    3358:	00430693          	addi	a3,t1,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    335c:	ffc00293          	li	t0,-4
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    3360:	010457b3          	srl	a5,s0,a6
    3364:	00f7f313          	andi	t1,a5,15
    3368:	006f85b3          	add	a1,t6,t1
    336c:	0005c303          	lbu	t1,0(a1)
    3370:	0006a783          	lw	a5,0(a3)
    3374:	0107d593          	srli	a1,a5,0x10
    3378:	0ff5f793          	zext.b	a5,a1
    337c:	fe078ae3          	beqz	a5,3370 <bsp_printf+0xf0>
        *((volatile u32*) address) = data;
    3380:	0063a023          	sw	t1,0(t2) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    3384:	ffc80813          	addi	a6,a6,-4
    3388:	fc581ce3          	bne	a6,t0,3360 <bsp_printf+0xe0>
    338c:	f61ff06f          	j	32ec <bsp_printf+0x6c>
                        bsp_printf_s(va_arg(ap,char*));
    3390:	00c12403          	lw	s0,12(sp)
    3394:	00042803          	lw	a6,0(s0)
    3398:	00440f93          	addi	t6,s0,4
    339c:	01f12623          	sw	t6,12(sp)
        while (*p)
    33a0:	00084303          	lbu	t1,0(a6)
    33a4:	f40304e3          	beqz	t1,32ec <bsp_printf+0x6c>
        return *((volatile u32*) address);
    33a8:	f80103b7          	lui	t2,0xf8010
    33ac:	f80102b7          	lui	t0,0xf8010
    33b0:	00438693          	addi	a3,t2,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
            _putchar(*(p++));
    33b4:	00180813          	addi	a6,a6,1
    33b8:	0006a583          	lw	a1,0(a3)
    33bc:	0105d793          	srli	a5,a1,0x10
    33c0:	0ff7f413          	zext.b	s0,a5
    33c4:	fe040ae3          	beqz	s0,33b8 <bsp_printf+0x138>
        *((volatile u32*) address) = data;
    33c8:	0062a023          	sw	t1,0(t0) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        while (*p)
    33cc:	00084303          	lbu	t1,0(a6)
    33d0:	fe0312e3          	bnez	t1,33b4 <bsp_printf+0x134>
    33d4:	f19ff06f          	j	32ec <bsp_printf+0x6c>
                        bsp_printf_d(va_arg(ap,int));
    33d8:	00c12383          	lw	t2,12(sp)
    33dc:	0003a783          	lw	a5,0(t2)
    33e0:	00438f93          	addi	t6,t2,4
    33e4:	01f12623          	sw	t6,12(sp)
        if (val < 0) {
    33e8:	1207c863          	bltz	a5,3518 <bsp_printf+0x298>
        for (i = 0; format[i]; i++)
    33ec:	01010313          	addi	t1,sp,16
    33f0:	00030693          	mv	a3,t1
            *(p++) = '0' + val % 10;
    33f4:	00a00293          	li	t0,10
        while (val || p == buffer) {
    33f8:	00079463          	bnez	a5,3400 <bsp_printf+0x180>
    33fc:	0a669863          	bne	a3,t1,34ac <bsp_printf+0x22c>
            *(p++) = '0' + val % 10;
    3400:	0257e5b3          	rem	a1,a5,t0
    3404:	00168693          	addi	a3,a3,1
    3408:	03058f93          	addi	t6,a1,48
            val = val / 10;
    340c:	0257c7b3          	div	a5,a5,t0
            *(p++) = '0' + val % 10;
    3410:	fff68fa3          	sb	t6,-1(a3)
            val = val / 10;
    3414:	fe5ff06f          	j	33f8 <bsp_printf+0x178>
                        bsp_printf_c(va_arg(ap,int));
    3418:	00c12403          	lw	s0,12(sp)
        return *((volatile u32*) address);
    341c:	f80106b7          	lui	a3,0xf8010
    3420:	00468313          	addi	t1,a3,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3424:	00042803          	lw	a6,0(s0)
    3428:	00440393          	addi	t2,s0,4
    342c:	00712623          	sw	t2,12(sp)
    3430:	00032283          	lw	t0,0(t1)
    3434:	0102d593          	srli	a1,t0,0x10
    3438:	0ff5f793          	zext.b	a5,a1
    343c:	fe078ae3          	beqz	a5,3430 <bsp_printf+0x1b0>
        write_u32(data, reg + UART_DATA);
    3440:	0ff87f93          	zext.b	t6,a6
        *((volatile u32*) address) = data;
    3444:	f8010437          	lui	s0,0xf8010
    3448:	01f42023          	sw	t6,0(s0) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
    }
    344c:	ea1ff06f          	j	32ec <bsp_printf+0x6c>
                        bsp_printf_X(va_arg(ap,int));
    3450:	00c12803          	lw	a6,12(sp)
        return *((volatile u32*) address);
    3454:	f80106b7          	lui	a3,0xf8010
    3458:	00006337          	lui	t1,0x6
    345c:	00480393          	addi	t2,a6,4
            bsp_printHex(val);
    3460:	00082403          	lw	s0,0(a6)
                        bsp_printf_X(va_arg(ap,int));
    3464:	00712623          	sw	t2,12(sp)
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    3468:	01c00813          	li	a6,28
    346c:	c7830f93          	addi	t6,t1,-904 # 5c78 <_data+0x60>
    3470:	f80103b7          	lui	t2,0xf8010
    3474:	00468693          	addi	a3,a3,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3478:	ffc00293          	li	t0,-4
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    347c:	010455b3          	srl	a1,s0,a6
    3480:	00f5f793          	andi	a5,a1,15
    3484:	00ff8333          	add	t1,t6,a5
    3488:	00034303          	lbu	t1,0(t1)
    348c:	0006a583          	lw	a1,0(a3)
        while(uart_writeAvailability(reg) == 0);
    3490:	0105d793          	srli	a5,a1,0x10
    3494:	0ff7f593          	zext.b	a1,a5
    3498:	fe058ae3          	beqz	a1,348c <bsp_printf+0x20c>
        *((volatile u32*) address) = data;
    349c:	0063a023          	sw	t1,0(t2) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    34a0:	ffc80813          	addi	a6,a6,-4
    34a4:	fc581ce3          	bne	a6,t0,347c <bsp_printf+0x1fc>
    34a8:	e45ff06f          	j	32ec <bsp_printf+0x6c>
        return *((volatile u32*) address);
    34ac:	f80107b7          	lui	a5,0xf8010
    34b0:	f80102b7          	lui	t0,0xf8010
    34b4:	00478593          	addi	a1,a5,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
            bsp_printf_c(*(--p));
    34b8:	fff6cf83          	lbu	t6,-1(a3)
    34bc:	fff68693          	addi	a3,a3,-1
    34c0:	0005a803          	lw	a6,0(a1)
    34c4:	01085413          	srli	s0,a6,0x10
    34c8:	0ff47393          	zext.b	t2,s0
    34cc:	fe038ae3          	beqz	t2,34c0 <bsp_printf+0x240>
        *((volatile u32*) address) = data;
    34d0:	01f2a023          	sw	t6,0(t0) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        while (p != buffer)
    34d4:	fe6692e3          	bne	a3,t1,34b8 <bsp_printf+0x238>
    34d8:	e15ff06f          	j	32ec <bsp_printf+0x6c>
        return *((volatile u32*) address);
    34dc:	f80103b7          	lui	t2,0xf8010
                while (format[++i]) {
    34e0:	00006fb7          	lui	t6,0x6
    34e4:	03c00313          	li	t1,60
    34e8:	c18f8813          	addi	a6,t6,-1000 # 5c18 <_data>
    34ec:	f80102b7          	lui	t0,0xf8010
    34f0:	00438693          	addi	a3,t2,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
            _putchar(*(p++));
    34f4:	00180813          	addi	a6,a6,1
    34f8:	0006a583          	lw	a1,0(a3)
    34fc:	0105d793          	srli	a5,a1,0x10
    3500:	0ff7f413          	zext.b	s0,a5
    3504:	fe040ae3          	beqz	s0,34f8 <bsp_printf+0x278>
        *((volatile u32*) address) = data;
    3508:	0062a023          	sw	t1,0(t0) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        while (*p)
    350c:	00084303          	lbu	t1,0(a6)
    3510:	fe0312e3          	bnez	t1,34f4 <bsp_printf+0x274>
    3514:	dd9ff06f          	j	32ec <bsp_printf+0x6c>
        return *((volatile u32*) address);
    3518:	f80102b7          	lui	t0,0xf8010
    351c:	00428593          	addi	a1,t0,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3520:	0005a683          	lw	a3,0(a1)
    3524:	0106d813          	srli	a6,a3,0x10
    3528:	0ff87413          	zext.b	s0,a6
    352c:	fe040ae3          	beqz	s0,3520 <bsp_printf+0x2a0>
        *((volatile u32*) address) = data;
    3530:	f8010337          	lui	t1,0xf8010
    3534:	02d00393          	li	t2,45
    3538:	00732023          	sw	t2,0(t1) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
            val = -val;
    353c:	40f007b3          	neg	a5,a5
    3540:	eadff06f          	j	33ec <bsp_printf+0x16c>

00003544 <halt>:
{
    3544:	ff010113          	addi	sp,sp,-16
    3548:	00912223          	sw	s1,4(sp)
    354c:	00050493          	mv	s1,a0
    bsp_printf("ERROR: %s (%d: %s)\r\n", what, rc, style_net_status_str(rc));
    3550:	00058513          	mv	a0,a1
{
    3554:	00812423          	sw	s0,8(sp)
    3558:	00112623          	sw	ra,12(sp)
    355c:	00058413          	mv	s0,a1
    bsp_printf("ERROR: %s (%d: %s)\r\n", what, rc, style_net_status_str(rc));
    3560:	2f4010ef          	jal	4854 <style_net_status_str>
    3564:	00050693          	mv	a3,a0
    3568:	00006537          	lui	a0,0x6
    356c:	00040613          	mv	a2,s0
    3570:	00048593          	mv	a1,s1
    3574:	c8c50513          	addi	a0,a0,-884 # 5c8c <_data+0x74>
    3578:	d09ff0ef          	jal	3280 <bsp_printf>
    while (1) {
    357c:	0000006f          	j	357c <halt+0x38>

00003580 <poll_display_switch>:
{
    3580:	fe010113          	addi	sp,sp,-32
    const uint32_t status = accel[STYLE_NET_REG_KEY12_STATUS / 4u];
    3584:	f81007b7          	lui	a5,0xf8100
{
    3588:	00812c23          	sw	s0,24(sp)
    const uint32_t status = accel[STYLE_NET_REG_KEY12_STATUS / 4u];
    358c:	09c7a403          	lw	s0,156(a5) # f810009c <__freertos_irq_stack_top+0xf80f7b1c>
{
    3590:	01412423          	sw	s4,8(sp)
    if (key1_level != last_key1_level) {
    3594:	8181a703          	lw	a4,-2024(gp) # 7378 <last_key1_level>
{
    3598:	01312623          	sw	s3,12(sp)
    const unsigned key1_level = (status & STYLE_NET_KEY1_LEVEL) != 0u;
    359c:	00145993          	srli	s3,s0,0x1
{
    35a0:	00912a23          	sw	s1,20(sp)
    35a4:	01212823          	sw	s2,16(sp)
    const unsigned key3_level = (status & STYLE_NET_KEY3_LEVEL) != 0u;
    35a8:	00545493          	srli	s1,s0,0x5
    const unsigned key2_level = (status & STYLE_NET_KEY2_LEVEL) != 0u;
    35ac:	00345913          	srli	s2,s0,0x3
{
    35b0:	00112e23          	sw	ra,28(sp)
    const unsigned key1_level = (status & STYLE_NET_KEY1_LEVEL) != 0u;
    35b4:	0019f993          	andi	s3,s3,1
    const unsigned key2_level = (status & STYLE_NET_KEY2_LEVEL) != 0u;
    35b8:	00197913          	andi	s2,s2,1
    const unsigned key3_level = (status & STYLE_NET_KEY3_LEVEL) != 0u;
    35bc:	0014f493          	andi	s1,s1,1
    if (key1_level != last_key1_level) {
    35c0:	01370c63          	beq	a4,s3,35d8 <poll_display_switch+0x58>
        bsp_printf("key1: GPIOR_22 level=%d\r\n", (int)key1_level);
    35c4:	00006537          	lui	a0,0x6
    35c8:	00098593          	mv	a1,s3
    35cc:	ca450513          	addi	a0,a0,-860 # 5ca4 <_data+0x8c>
    35d0:	cb1ff0ef          	jal	3280 <bsp_printf>
        last_key1_level = key1_level;
    35d4:	8131ac23          	sw	s3,-2024(gp) # 7378 <last_key1_level>
    if (key2_level != last_key2_level) {
    35d8:	8141a083          	lw	ra,-2028(gp) # 7374 <last_key2_level>
    35dc:	01208c63          	beq	ra,s2,35f4 <poll_display_switch+0x74>
        bsp_printf("key2: GPIOR_21 level=%d\r\n", (int)key2_level);
    35e0:	000062b7          	lui	t0,0x6
    35e4:	00090593          	mv	a1,s2
    35e8:	cc028513          	addi	a0,t0,-832 # 5cc0 <_data+0xa8>
    35ec:	c95ff0ef          	jal	3280 <bsp_printf>
        last_key2_level = key2_level;
    35f0:	8121aa23          	sw	s2,-2028(gp) # 7374 <last_key2_level>
    if (key3_level != last_key3_level) {
    35f4:	8101a303          	lw	t1,-2032(gp) # 7370 <last_key3_level>
    35f8:	00930c63          	beq	t1,s1,3610 <poll_display_switch+0x90>
        bsp_printf("key3: GPIOL_03 level=%d\r\n", (int)key3_level);
    35fc:	000063b7          	lui	t2,0x6
    3600:	00048593          	mv	a1,s1
    3604:	cdc38513          	addi	a0,t2,-804 # 5cdc <_data+0xc4>
    3608:	c79ff0ef          	jal	3280 <bsp_printf>
        last_key3_level = key3_level;
    360c:	8091a823          	sw	s1,-2032(gp) # 7370 <last_key3_level>
    if ((status & STYLE_NET_KEY1_EVENT) != 0u) {
    3610:	00147593          	andi	a1,s0,1
    3614:	02059a63          	bnez	a1,3648 <poll_display_switch+0xc8>
    if ((status & STYLE_NET_KEY2_EVENT) != 0u) {
    3618:	00447793          	andi	a5,s0,4
    361c:	06079263          	bnez	a5,3680 <poll_display_switch+0x100>
    if ((status & STYLE_NET_KEY3_EVENT) != 0u) {
    3620:	01047413          	andi	s0,s0,16
    3624:	0c041263          	bnez	s0,36e8 <poll_display_switch+0x168>
}
    3628:	01c12083          	lw	ra,28(sp)
    362c:	01812403          	lw	s0,24(sp)
    3630:	01412483          	lw	s1,20(sp)
    3634:	01012903          	lw	s2,16(sp)
    3638:	00c12983          	lw	s3,12(sp)
    363c:	00812a03          	lw	s4,8(sp)
    3640:	02010113          	addi	sp,sp,32
    3644:	00008067          	ret
        bsp_printf("key1: styled/split toggle\r\n");
    3648:	00006637          	lui	a2,0x6
    364c:	cf860513          	addi	a0,a2,-776 # 5cf8 <_data+0xe0>
    3650:	c31ff0ef          	jal	3280 <bsp_printf>
        set_display_mode(active_display_mode == STYLE_NET_DISPLAY_STYLED
    3654:	83c1a683          	lw	a3,-1988(gp) # 739c <active_display_mode>
    3658:	00200893          	li	a7,2
    365c:	11168c63          	beq	a3,a7,3774 <poll_display_switch+0x1f4>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3660:	f8100e37          	lui	t3,0xf8100
    active_display_mode = mode;
    3664:	8311ae23          	sw	a7,-1988(gp) # 739c <active_display_mode>
        bsp_printf("display mode: styled\r\n");
    3668:	00006eb7          	lui	t4,0x6
    366c:	d34e8513          	addi	a0,t4,-716 # 5d34 <_data+0x11c>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3670:	0b1e2023          	sw	a7,160(t3) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: styled\r\n");
    3674:	c0dff0ef          	jal	3280 <bsp_printf>
    if ((status & STYLE_NET_KEY2_EVENT) != 0u) {
    3678:	00447793          	andi	a5,s0,4
    367c:	fa0782e3          	beqz	a5,3620 <poll_display_switch+0xa0>
        bsp_printf("key2: strength +\r\n");
    3680:	00006737          	lui	a4,0x6
    3684:	d4c70513          	addi	a0,a4,-692 # 5d4c <_data+0x134>
    3688:	bf9ff0ef          	jal	3280 <bsp_printf>
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    368c:	83c1aa03          	lw	s4,-1988(gp) # 739c <active_display_mode>
    3690:	00300293          	li	t0,3
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    3694:	8381a483          	lw	s1,-1992(gp) # 7398 <active_style_strength>
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    3698:	105a1e63          	bne	s4,t0,37b4 <poll_display_switch+0x234>
        value = active_style_strength + (unsigned)delta;
    369c:	01048593          	addi	a1,s1,16
        if (value > 255u)
    36a0:	0ff00313          	li	t1,255
    36a4:	0eb36663          	bltu	t1,a1,3790 <poll_display_switch+0x210>
        const unsigned percent = (value * 100u + 127u) / 255u;
    36a8:	06400393          	li	t2,100
    36ac:	02758633          	mul	a2,a1,t2
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    36b0:	0ff00e13          	li	t3,255
    active_style_strength = value;
    36b4:	82b1ac23          	sw	a1,-1992(gp) # 7398 <active_style_strength>
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    36b8:	f8100837          	lui	a6,0xf8100
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    36bc:	000066b7          	lui	a3,0x6
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    36c0:	0ab82223          	sw	a1,164(a6) # f81000a4 <__freertos_irq_stack_top+0xf80f7b24>
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    36c4:	d8868513          	addi	a0,a3,-632 # 5d88 <_data+0x170>
    if ((status & STYLE_NET_KEY3_EVENT) != 0u) {
    36c8:	01047413          	andi	s0,s0,16
        const unsigned percent = (value * 100u + 127u) / 255u;
    36cc:	07f60893          	addi	a7,a2,127
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    36d0:	03c8d633          	divu	a2,a7,t3
    36d4:	badff0ef          	jal	3280 <bsp_printf>
    accel[STYLE_NET_REG_HUD / 4u] = type;
    36d8:	f81005b7          	lui	a1,0xf8100
    36dc:	00100e93          	li	t4,1
    36e0:	0bd5a423          	sw	t4,168(a1) # f81000a8 <__freertos_irq_stack_top+0xf80f7b28>
    if ((status & STYLE_NET_KEY3_EVENT) != 0u) {
    36e4:	f40402e3          	beqz	s0,3628 <poll_display_switch+0xa8>
        bsp_printf("key3: strength -\r\n");
    36e8:	00006f37          	lui	t5,0x6
    36ec:	da8f0513          	addi	a0,t5,-600 # 5da8 <_data+0x190>
    36f0:	b91ff0ef          	jal	3280 <bsp_printf>
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    36f4:	83c1a703          	lw	a4,-1988(gp) # 739c <active_display_mode>
    36f8:	00300793          	li	a5,3
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    36fc:	8381a903          	lw	s2,-1992(gp) # 7398 <active_style_strength>
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    3700:	0ef71063          	bne	a4,a5,37e0 <poll_display_switch+0x260>
                    : 0u;
    3704:	01000493          	li	s1,16
    3708:	00090093          	mv	ra,s2
    370c:	08996a63          	bltu	s2,s1,37a0 <poll_display_switch+0x220>
    3710:	ff008593          	addi	a1,ra,-16
    if (value > 255u)
    3714:	0ff00993          	li	s3,255
    3718:	08b9e063          	bltu	s3,a1,3798 <poll_display_switch+0x218>
        const unsigned percent = (value * 100u + 127u) / 255u;
    371c:	06400313          	li	t1,100
    3720:	026583b3          	mul	t2,a1,t1
    active_style_strength = value;
    3724:	82b1ac23          	sw	a1,-1992(gp) # 7398 <active_style_strength>
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    3728:	f8100637          	lui	a2,0xf8100
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    372c:	0ff00893          	li	a7,255
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    3730:	0ab62223          	sw	a1,164(a2) # f81000a4 <__freertos_irq_stack_top+0xf80f7b24>
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    3734:	00006837          	lui	a6,0x6
    3738:	d8880513          	addi	a0,a6,-632 # 5d88 <_data+0x170>
        const unsigned percent = (value * 100u + 127u) / 255u;
    373c:	07f38693          	addi	a3,t2,127
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    3740:	0316d633          	divu	a2,a3,a7
    3744:	b3dff0ef          	jal	3280 <bsp_printf>
}
    3748:	01c12083          	lw	ra,28(sp)
    374c:	01812403          	lw	s0,24(sp)
    accel[STYLE_NET_REG_HUD / 4u] = type;
    3750:	f8100e37          	lui	t3,0xf8100
    3754:	00100593          	li	a1,1
    3758:	0abe2423          	sw	a1,168(t3) # f81000a8 <__freertos_irq_stack_top+0xf80f7b28>
}
    375c:	01412483          	lw	s1,20(sp)
    3760:	01012903          	lw	s2,16(sp)
    3764:	00c12983          	lw	s3,12(sp)
    3768:	00812a03          	lw	s4,8(sp)
    376c:	02010113          	addi	sp,sp,32
    3770:	00008067          	ret
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3774:	f8100f37          	lui	t5,0xf8100
    active_display_mode = mode;
    3778:	8201ae23          	sw	zero,-1988(gp) # 739c <active_display_mode>
        bsp_printf("display mode: split compare\r\n");
    377c:	00006fb7          	lui	t6,0x6
    3780:	d14f8513          	addi	a0,t6,-748 # 5d14 <_data+0xfc>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3784:	0a0f2023          	sw	zero,160(t5) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: split compare\r\n");
    3788:	af9ff0ef          	jal	3280 <bsp_printf>
    378c:	e8dff06f          	j	3618 <poll_display_switch+0x98>
        if (value > 255u)
    3790:	0ff00593          	li	a1,255
    3794:	f15ff06f          	j	36a8 <poll_display_switch+0x128>
    if (value > 255u)
    3798:	0ff00593          	li	a1,255
    379c:	f81ff06f          	j	371c <poll_display_switch+0x19c>
                    : 0u;
    37a0:	01000093          	li	ra,16
    37a4:	ff008593          	addi	a1,ra,-16
    if (value > 255u)
    37a8:	0ff00993          	li	s3,255
    37ac:	f6b9f8e3          	bgeu	s3,a1,371c <poll_display_switch+0x19c>
    37b0:	fe9ff06f          	j	3798 <poll_display_switch+0x218>
    active_display_mode = mode;
    37b4:	8251ae23          	sw	t0,-1988(gp) # 739c <active_display_mode>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    37b8:	f81000b7          	lui	ra,0xf8100
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    37bc:	000069b7          	lui	s3,0x6
    37c0:	00048593          	mv	a1,s1
    37c4:	d6098513          	addi	a0,s3,-672 # 5d60 <_data+0x148>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    37c8:	0a50a023          	sw	t0,160(ra) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    37cc:	ab5ff0ef          	jal	3280 <bsp_printf>
        value = active_style_strength + (unsigned)delta;
    37d0:	01048593          	addi	a1,s1,16
        if (value > 255u)
    37d4:	0ff00313          	li	t1,255
    37d8:	ecb378e3          	bgeu	t1,a1,36a8 <poll_display_switch+0x128>
    37dc:	fb5ff06f          	j	3790 <poll_display_switch+0x210>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    37e0:	f81002b7          	lui	t0,0xf8100
    active_display_mode = mode;
    37e4:	82f1ae23          	sw	a5,-1988(gp) # 739c <active_display_mode>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    37e8:	00006537          	lui	a0,0x6
    37ec:	00090593          	mv	a1,s2
    37f0:	d6050513          	addi	a0,a0,-672 # 5d60 <_data+0x148>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    37f4:	0af2a023          	sw	a5,160(t0) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    37f8:	a89ff0ef          	jal	3280 <bsp_printf>
                    : 0u;
    37fc:	01000493          	li	s1,16
    3800:	00090093          	mv	ra,s2
    3804:	f09976e3          	bgeu	s2,s1,3710 <poll_display_switch+0x190>
    3808:	f99ff06f          	j	37a0 <poll_display_switch+0x220>

0000380c <poll_style_switch>:
{
    380c:	fe010113          	addi	sp,sp,-32
    3810:	00812c23          	sw	s0,24(sp)
    3814:	01312623          	sw	s3,12(sp)
        return *((volatile u32*) address);
    3818:	f8010437          	lui	s0,0xf8010
    381c:	000069b7          	lui	s3,0x6
    3820:	00912a23          	sw	s1,20(sp)
    3824:	01212823          	sw	s2,16(sp)
    3828:	00112e23          	sw	ra,28(sp)
    382c:	01412423          	sw	s4,8(sp)
    3830:	01512223          	sw	s5,4(sp)
    3834:	00440413          	addi	s0,s0,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3838:	f8010937          	lui	s2,0xf8010
    383c:	04b00493          	li	s1,75
    3840:	44098993          	addi	s3,s3,1088 # 6440 <_data+0x828>
    3844:	00042783          	lw	a5,0(s0)
        return read_u32(reg + UART_STATUS) >> 24;
    3848:	0187d093          	srli	ra,a5,0x18
    while (uart_readOccupancy(BSP_UART_TERMINAL) != 0u) {
    384c:	06008263          	beqz	ra,38b0 <poll_style_switch+0xa4>
    3850:	00042283          	lw	t0,0(s0)
    3854:	0182d313          	srli	t1,t0,0x18
*          for reading. Once data is available, it reads the character data from
*          the UART data register and returns it.
*
******************************************************************************/
    static char uart_read(u32 reg){
        while(uart_readOccupancy(reg) == 0);
    3858:	fe030ce3          	beqz	t1,3850 <poll_style_switch+0x44>
    385c:	00092703          	lw	a4,0(s2) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        if (c >= '1' && c <= '3') {
    3860:	fd570393          	addi	t2,a4,-43
    3864:	0ff3f513          	zext.b	a0,t2
    3868:	fca4eee3          	bltu	s1,a0,3844 <poll_style_switch+0x38>
    386c:	00251593          	slli	a1,a0,0x2
    3870:	01358633          	add	a2,a1,s3
    3874:	00062683          	lw	a3,0(a2)
    3878:	00068067          	jr	a3
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    387c:	83c1a703          	lw	a4,-1988(gp) # 739c <active_display_mode>
    3880:	00300393          	li	t2,3
    3884:	fc7700e3          	beq	a4,t2,3844 <poll_style_switch+0x38>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    3888:	8381a583          	lw	a1,-1992(gp) # 7398 <active_style_strength>
    active_display_mode = mode;
    388c:	8271ae23          	sw	t2,-1988(gp) # 739c <active_display_mode>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3890:	f81006b7          	lui	a3,0xf8100
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    3894:	00006837          	lui	a6,0x6
    3898:	d6080513          	addi	a0,a6,-672 # 5d60 <_data+0x148>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    389c:	0a76a023          	sw	t2,160(a3) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    38a0:	9e1ff0ef          	jal	3280 <bsp_printf>
    38a4:	00042783          	lw	a5,0(s0)
        return read_u32(reg + UART_STATUS) >> 24;
    38a8:	0187d093          	srli	ra,a5,0x18
    while (uart_readOccupancy(BSP_UART_TERMINAL) != 0u) {
    38ac:	fa0092e3          	bnez	ra,3850 <poll_style_switch+0x44>
}
    38b0:	01c12083          	lw	ra,28(sp)
    38b4:	01812403          	lw	s0,24(sp)
    38b8:	01412483          	lw	s1,20(sp)
    38bc:	01012903          	lw	s2,16(sp)
    38c0:	00c12983          	lw	s3,12(sp)
    38c4:	00812a03          	lw	s4,8(sp)
    38c8:	00412a83          	lw	s5,4(sp)
    38cc:	02010113          	addi	sp,sp,32
    38d0:	00008067          	ret
    active_display_mode = mode;
    38d4:	00200593          	li	a1,2
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    38d8:	f81008b7          	lui	a7,0xf8100
    active_display_mode = mode;
    38dc:	82b1ae23          	sw	a1,-1988(gp) # 739c <active_display_mode>
        bsp_printf("display mode: styled\r\n");
    38e0:	00006a37          	lui	s4,0x6
    38e4:	d34a0513          	addi	a0,s4,-716 # 5d34 <_data+0x11c>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    38e8:	0ab8a023          	sw	a1,160(a7) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: styled\r\n");
    38ec:	995ff0ef          	jal	3280 <bsp_printf>
    38f0:	f55ff06f          	j	3844 <poll_style_switch+0x38>
            index = (unsigned)(c - '1');
    38f4:	0ff77a93          	zext.b	s5,a4
    38f8:	fcfa8e13          	addi	t3,s5,-49
    ctx.model_base = active_style->model_base;
    38fc:	001e1e93          	slli	t4,t3,0x1
    3900:	01ce8f33          	add	t5,t4,t3
    3904:	00006fb7          	lui	t6,0x6
    3908:	003f1793          	slli	a5,t5,0x3
    390c:	5f4f8293          	addi	t0,t6,1524 # 65f4 <style_multistyle_entries>
    3910:	00f28333          	add	t1,t0,a5
    3914:	00832603          	lw	a2,8(t1)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3918:	00432583          	lw	a1,4(t1)
    391c:	000060b7          	lui	ra,0x6
    3920:	dbc08513          	addi	a0,ra,-580 # 5dbc <_data+0x1a4>
    active_style_index = index;
    3924:	85c1a023          	sw	t3,-1984(gp) # 73a0 <active_style_index>
    ctx.model_base = active_style->model_base;
    3928:	88c1a623          	sw	a2,-1908(gp) # 73ec <ctx+0x4>
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    392c:	955ff0ef          	jal	3280 <bsp_printf>
}
    3930:	f15ff06f          	j	3844 <poll_style_switch+0x38>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3934:	f81006b7          	lui	a3,0xf8100
    active_display_mode = mode;
    3938:	8201ae23          	sw	zero,-1988(gp) # 739c <active_display_mode>
        bsp_printf("display mode: split compare\r\n");
    393c:	00006837          	lui	a6,0x6
    3940:	d1480513          	addi	a0,a6,-748 # 5d14 <_data+0xfc>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3944:	0a06a023          	sw	zero,160(a3) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: split compare\r\n");
    3948:	939ff0ef          	jal	3280 <bsp_printf>
    394c:	ef9ff06f          	j	3844 <poll_style_switch+0x38>
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    3950:	83c1a883          	lw	a7,-1988(gp) # 739c <active_display_mode>
    3954:	00300613          	li	a2,3
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    3958:	8381aa83          	lw	s5,-1992(gp) # 7398 <active_style_strength>
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    395c:	1ec89063          	bne	a7,a2,3b3c <poll_style_switch+0x330>
                    : 0u;
    3960:	01000f13          	li	t5,16
    3964:	000a8f93          	mv	t6,s5
    3968:	19eaea63          	bltu	s5,t5,3afc <poll_style_switch+0x2f0>
    396c:	ff0f8593          	addi	a1,t6,-16
    if (value > 255u)
    3970:	0ff00793          	li	a5,255
    3974:	18b7e063          	bltu	a5,a1,3af4 <poll_style_switch+0x2e8>
        const unsigned percent = (value * 100u + 127u) / 255u;
    3978:	06400293          	li	t0,100
    397c:	02558333          	mul	t1,a1,t0
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    3980:	f81000b7          	lui	ra,0xf8100
    active_style_strength = value;
    3984:	82b1ac23          	sw	a1,-1992(gp) # 7398 <active_style_strength>
        const unsigned percent = (value * 100u + 127u) / 255u;
    3988:	07f30e93          	addi	t4,t1,127
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    398c:	0ff00f13          	li	t5,255
    3990:	00006e37          	lui	t3,0x6
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    3994:	0ab0a223          	sw	a1,164(ra) # f81000a4 <__freertos_irq_stack_top+0xf80f7b24>
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    3998:	d88e0513          	addi	a0,t3,-632 # 5d88 <_data+0x170>
    399c:	03eed633          	divu	a2,t4,t5
    39a0:	8e1ff0ef          	jal	3280 <bsp_printf>
    accel[STYLE_NET_REG_HUD / 4u] = type;
    39a4:	f81005b7          	lui	a1,0xf8100
    39a8:	00100f93          	li	t6,1
    39ac:	0bf5a423          	sw	t6,168(a1) # f81000a8 <__freertos_irq_stack_top+0xf80f7b28>
}
    39b0:	e95ff06f          	j	3844 <poll_style_switch+0x38>
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    39b4:	83c1a383          	lw	t2,-1988(gp) # 739c <active_display_mode>
    39b8:	00300813          	li	a6,3
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    39bc:	8381aa03          	lw	s4,-1992(gp) # 7398 <active_style_strength>
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
    39c0:	15039863          	bne	t2,a6,3b10 <poll_style_switch+0x304>
        value = active_style_strength + (unsigned)delta;
    39c4:	010a0593          	addi	a1,s4,16
        if (value > 255u)
    39c8:	0ff00893          	li	a7,255
    39cc:	10b8e863          	bltu	a7,a1,3adc <poll_style_switch+0x2d0>
        const unsigned percent = (value * 100u + 127u) / 255u;
    39d0:	06400613          	li	a2,100
    39d4:	02c58333          	mul	t1,a1,a2
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    39d8:	f81000b7          	lui	ra,0xf8100
    active_style_strength = value;
    39dc:	82b1ac23          	sw	a1,-1992(gp) # 7398 <active_style_strength>
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    39e0:	fa9ff06f          	j	3988 <poll_style_switch+0x17c>
    ctx.model_base = active_style->model_base;
    39e4:	00006837          	lui	a6,0x6
    39e8:	5f480893          	addi	a7,a6,1524 # 65f4 <style_multistyle_entries>
    39ec:	0208a603          	lw	a2,32(a7)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    39f0:	01c8a583          	lw	a1,28(a7)
    39f4:	00006a37          	lui	s4,0x6
    active_style_index = index;
    39f8:	00100e13          	li	t3,1
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    39fc:	dbca0513          	addi	a0,s4,-580 # 5dbc <_data+0x1a4>
    active_style_index = index;
    3a00:	85c1a023          	sw	t3,-1984(gp) # 73a0 <active_style_index>
    ctx.model_base = active_style->model_base;
    3a04:	88c1a623          	sw	a2,-1908(gp) # 73ec <ctx+0x4>
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3a08:	879ff0ef          	jal	3280 <bsp_printf>
}
    3a0c:	e39ff06f          	j	3844 <poll_style_switch+0x38>
    if (value > 255u)
    3a10:	8381a583          	lw	a1,-1992(gp) # 7398 <active_style_strength>
    3a14:	0ff00f93          	li	t6,255
    3a18:	0abfee63          	bltu	t6,a1,3ad4 <poll_style_switch+0x2c8>
        const unsigned percent = (value * 100u + 127u) / 255u;
    3a1c:	06400793          	li	a5,100
    3a20:	02f580b3          	mul	ra,a1,a5
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    3a24:	0ff00393          	li	t2,255
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    3a28:	f81002b7          	lui	t0,0xf8100
    active_style_strength = value;
    3a2c:	82b1ac23          	sw	a1,-1992(gp) # 7398 <active_style_strength>
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    3a30:	00006337          	lui	t1,0x6
    3a34:	d8830513          	addi	a0,t1,-632 # 5d88 <_data+0x170>
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    3a38:	0ab2a223          	sw	a1,164(t0) # f81000a4 <__freertos_irq_stack_top+0xf80f7b24>
        const unsigned percent = (value * 100u + 127u) / 255u;
    3a3c:	07f08713          	addi	a4,ra,127 # f810007f <__freertos_irq_stack_top+0xf80f7aff>
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    3a40:	02775633          	divu	a2,a4,t2
    3a44:	83dff0ef          	jal	3280 <bsp_printf>
    3a48:	dfdff06f          	j	3844 <poll_style_switch+0x38>
    ctx.model_base = active_style->model_base;
    3a4c:	00006537          	lui	a0,0x6
    3a50:	5f450593          	addi	a1,a0,1524 # 65f4 <style_multistyle_entries>
    3a54:	0085a603          	lw	a2,8(a1)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3a58:	0045a583          	lw	a1,4(a1)
    3a5c:	000066b7          	lui	a3,0x6
    3a60:	dbc68513          	addi	a0,a3,-580 # 5dbc <_data+0x1a4>
    active_style_index = index;
    3a64:	8401a023          	sw	zero,-1984(gp) # 73a0 <active_style_index>
    ctx.model_base = active_style->model_base;
    3a68:	88c1a623          	sw	a2,-1908(gp) # 73ec <ctx+0x4>
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3a6c:	815ff0ef          	jal	3280 <bsp_printf>
}
    3a70:	dd5ff06f          	j	3844 <poll_style_switch+0x38>
    ctx.model_base = active_style->model_base;
    3a74:	00006637          	lui	a2,0x6
    3a78:	5f460a13          	addi	s4,a2,1524 # 65f4 <style_multistyle_entries>
    3a7c:	038a2603          	lw	a2,56(s4)
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3a80:	034a2583          	lw	a1,52(s4)
    3a84:	00006ab7          	lui	s5,0x6
    active_style_index = index;
    3a88:	00200e93          	li	t4,2
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3a8c:	dbca8513          	addi	a0,s5,-580 # 5dbc <_data+0x1a4>
    active_style_index = index;
    3a90:	85d1a023          	sw	t4,-1984(gp) # 73a0 <active_style_index>
    ctx.model_base = active_style->model_base;
    3a94:	88c1a623          	sw	a2,-1908(gp) # 73ec <ctx+0x4>
    bsp_printf("style selected: %s (model @0x%x)\r\n",
    3a98:	fe8ff0ef          	jal	3280 <bsp_printf>
}
    3a9c:	da9ff06f          	j	3844 <poll_style_switch+0x38>
            bsp_printf("styles: 1=future 2=vangogh 3=cubism\r\n");
    3aa0:	00006fb7          	lui	t6,0x6
    3aa4:	de0f8513          	addi	a0,t6,-544 # 5de0 <_data+0x1c8>
    3aa8:	fd8ff0ef          	jal	3280 <bsp_printf>
            bsp_printf("display: 0=split 5=styled 6=mix\r\n");
    3aac:	000067b7          	lui	a5,0x6
    3ab0:	e0878513          	addi	a0,a5,-504 # 5e08 <_data+0x1f0>
    3ab4:	fccff0ef          	jal	3280 <bsp_printf>
            bsp_printf("intensity: +/- step 16, i=read\r\n");
    3ab8:	000062b7          	lui	t0,0x6
    3abc:	e2c28513          	addi	a0,t0,-468 # 5e2c <_data+0x214>
    3ac0:	fc0ff0ef          	jal	3280 <bsp_printf>
            bsp_printf("keys: KEY0=next style; KEY2=+ KEY3=-\r\n");
    3ac4:	00006337          	lui	t1,0x6
    3ac8:	e5030513          	addi	a0,t1,-432 # 5e50 <_data+0x238>
    3acc:	fb4ff0ef          	jal	3280 <bsp_printf>
    3ad0:	d75ff06f          	j	3844 <poll_style_switch+0x38>
    if (value > 255u)
    3ad4:	0ff00593          	li	a1,255
    3ad8:	f45ff06f          	j	3a1c <poll_style_switch+0x210>
        if (value > 255u)
    3adc:	0ff00593          	li	a1,255
        const unsigned percent = (value * 100u + 127u) / 255u;
    3ae0:	06400613          	li	a2,100
    3ae4:	02c58333          	mul	t1,a1,a2
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    3ae8:	f81000b7          	lui	ra,0xf8100
    active_style_strength = value;
    3aec:	82b1ac23          	sw	a1,-1992(gp) # 7398 <active_style_strength>
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    3af0:	e99ff06f          	j	3988 <poll_style_switch+0x17c>
    if (value > 255u)
    3af4:	0ff00593          	li	a1,255
    3af8:	e81ff06f          	j	3978 <poll_style_switch+0x16c>
                    : 0u;
    3afc:	01000f93          	li	t6,16
    3b00:	ff0f8593          	addi	a1,t6,-16
    if (value > 255u)
    3b04:	0ff00793          	li	a5,255
    3b08:	e6b7f8e3          	bgeu	a5,a1,3978 <poll_style_switch+0x16c>
    3b0c:	fe9ff06f          	j	3af4 <poll_style_switch+0x2e8>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3b10:	f81006b7          	lui	a3,0xf8100
    active_display_mode = mode;
    3b14:	8301ae23          	sw	a6,-1988(gp) # 739c <active_display_mode>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    3b18:	00006537          	lui	a0,0x6
    3b1c:	000a0593          	mv	a1,s4
    3b20:	d6050513          	addi	a0,a0,-672 # 5d60 <_data+0x148>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3b24:	0b06a023          	sw	a6,160(a3) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    3b28:	f58ff0ef          	jal	3280 <bsp_printf>
        value = active_style_strength + (unsigned)delta;
    3b2c:	010a0593          	addi	a1,s4,16
        if (value > 255u)
    3b30:	0ff00893          	li	a7,255
    3b34:	e8b8fee3          	bgeu	a7,a1,39d0 <poll_style_switch+0x1c4>
    3b38:	fa5ff06f          	j	3adc <poll_style_switch+0x2d0>
    active_display_mode = mode;
    3b3c:	82c1ae23          	sw	a2,-1988(gp) # 739c <active_display_mode>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3b40:	f8100e37          	lui	t3,0xf8100
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    3b44:	00006eb7          	lui	t4,0x6
    3b48:	000a8593          	mv	a1,s5
    3b4c:	d60e8513          	addi	a0,t4,-672 # 5d60 <_data+0x148>
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    3b50:	0ace2023          	sw	a2,160(t3) # f81000a0 <__freertos_irq_stack_top+0xf80f7b20>
        bsp_printf("display mode: interpolation (%u/255)\r\n",
    3b54:	f2cff0ef          	jal	3280 <bsp_printf>
                    : 0u;
    3b58:	01000f13          	li	t5,16
    3b5c:	000a8f93          	mv	t6,s5
    3b60:	e1eaf6e3          	bgeu	s5,t5,396c <poll_style_switch+0x160>
    3b64:	f99ff06f          	j	3afc <poll_style_switch+0x2f0>

00003b68 <trap>:
    const int32_t mcause = (int32_t)csr_read(mcause);
    3b68:	342025f3          	csrr	a1,mcause
    if (mcause < 0 && (mcause & 0x1f) == CAUSE_MACHINE_EXTERNAL) {
    3b6c:	0005d863          	bgez	a1,3b7c <trap+0x14>
    3b70:	01f5f793          	andi	a5,a1,31
    3b74:	00b00713          	li	a4,11
    3b78:	00e78e63          	beq	a5,a4,3b94 <trap+0x2c>
    bsp_printf("FATAL: unexpected trap, mcause=0x%x\r\n", (unsigned)mcause);
    3b7c:	00006537          	lui	a0,0x6
{
    3b80:	ff010113          	addi	sp,sp,-16
    bsp_printf("FATAL: unexpected trap, mcause=0x%x\r\n", (unsigned)mcause);
    3b84:	e7850513          	addi	a0,a0,-392 # 5e78 <_data+0x260>
{
    3b88:	00112623          	sw	ra,12(sp)
    bsp_printf("FATAL: unexpected trap, mcause=0x%x\r\n", (unsigned)mcause);
    3b8c:	ef4ff0ef          	jal	3280 <bsp_printf>
    while (1) {
    3b90:	0000006f          	j	3b90 <trap+0x28>
        style_net_irq_handler();
    3b94:	5310106f          	j	58c4 <style_net_irq_handler>

00003b98 <_close_r>:
int _close_r(struct _reent *ptr, int fd)
{
    (void)ptr;
    (void)fd;
    return -1;
}
    3b98:	fff00513          	li	a0,-1
    3b9c:	00008067          	ret

00003ba0 <_lseek_r>:
    (void)ptr;
    (void)fd;
    (void)offset;
    (void)whence;
    return (_off_t)0;
}
    3ba0:	00000513          	li	a0,0
    3ba4:	00008067          	ret

00003ba8 <_read_r>:
    (void)ptr;
    (void)fd;
    (void)buf;
    (void)count;
    return (_ssize_t)0;
}
    3ba8:	00000513          	li	a0,0
    3bac:	00008067          	ret

00003bb0 <_write_r>:
{
    (void)ptr;
    (void)fd;
    (void)buf;
    return (_ssize_t)count;
}
    3bb0:	00068513          	mv	a0,a3
    3bb4:	00008067          	ret

00003bb8 <_fstat_r>:

int _fstat_r(struct _reent *ptr, int fd, struct stat *st)
{
    (void)ptr;
    (void)fd;
    if (st) {
    3bb8:	00060663          	beqz	a2,3bc4 <_fstat_r+0xc>
        st->st_mode = S_IFCHR;
    3bbc:	000027b7          	lui	a5,0x2
    3bc0:	00f62223          	sw	a5,4(a2)
    }
    return 0;
}
    3bc4:	00000513          	li	a0,0
    3bc8:	00008067          	ret

00003bcc <_isatty_r>:
int _isatty_r(struct _reent *ptr, int fd)
{
    (void)ptr;
    (void)fd;
    return 1;
}
    3bcc:	00100513          	li	a0,1
    3bd0:	00008067          	ret

00003bd4 <_open_r>:

int _open_r(struct _reent *ptr, const char *path, int flags, int mode)
{
    3bd4:	ff010113          	addi	sp,sp,-16
    3bd8:	00112623          	sw	ra,12(sp)
    (void)ptr;
    (void)path;
    (void)flags;
    (void)mode;
    errno = ENOSYS;
    3bdc:	c94fd0ef          	jal	1070 <__errno>
    return -1;
}
    3be0:	00c12083          	lw	ra,12(sp)
    errno = ENOSYS;
    3be4:	05800793          	li	a5,88
    3be8:	00f52023          	sw	a5,0(a0)
}
    3bec:	fff00513          	li	a0,-1
    3bf0:	01010113          	addi	sp,sp,16
    3bf4:	00008067          	ret

00003bf8 <bsp_printf>:
    {
    3bf8:	fa010113          	addi	sp,sp,-96
        for (i = 0; format[i]; i++)
    3bfc:	00054f83          	lbu	t6,0(a0)
    {
    3c00:	04f12a23          	sw	a5,84(sp)
        va_start(ap, format);
    3c04:	04410793          	addi	a5,sp,68
    {
    3c08:	04b12223          	sw	a1,68(sp)
    3c0c:	04c12423          	sw	a2,72(sp)
    3c10:	04d12623          	sw	a3,76(sp)
    3c14:	04e12823          	sw	a4,80(sp)
    3c18:	05012c23          	sw	a6,88(sp)
    3c1c:	05112e23          	sw	a7,92(sp)
        va_start(ap, format);
    3c20:	00f12623          	sw	a5,12(sp)
        for (i = 0; format[i]; i++)
    3c24:	040f8a63          	beqz	t6,3c78 <bsp_printf+0x80>
    3c28:	f8010737          	lui	a4,0xf8010
    3c2c:	00006eb7          	lui	t4,0x6
    3c30:	02812e23          	sw	s0,60(sp)
    3c34:	00000613          	li	a2,0
            if (format[i] == '%') {
    3c38:	02500893          	li	a7,37
    3c3c:	02000f13          	li	t5,32
    3c40:	570e8e93          	addi	t4,t4,1392 # 6570 <_data+0x958>
    3c44:	f8010e37          	lui	t3,0xf8010
    3c48:	00470713          	addi	a4,a4,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3c4c:	031f8a63          	beq	t6,a7,3c80 <bsp_printf+0x88>
    3c50:	00072283          	lw	t0,0(a4)
        while(uart_writeAvailability(reg) == 0);
    3c54:	0102d693          	srli	a3,t0,0x10
    3c58:	0ff6f393          	zext.b	t2,a3
    3c5c:	fe038ae3          	beqz	t2,3c50 <bsp_printf+0x58>
        *((volatile u32*) address) = data;
    3c60:	01fe2023          	sw	t6,0(t3) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        for (i = 0; format[i]; i++)
    3c64:	00160613          	addi	a2,a2,1
    3c68:	00c50433          	add	s0,a0,a2
    3c6c:	00044f83          	lbu	t6,0(s0)
    3c70:	fc0f9ee3          	bnez	t6,3c4c <bsp_printf+0x54>
    3c74:	03c12403          	lw	s0,60(sp)
    }
    3c78:	06010113          	addi	sp,sp,96
    3c7c:	00008067          	ret
                while (format[++i]) {
    3c80:	00160613          	addi	a2,a2,1
    3c84:	00c50333          	add	t1,a0,a2
    3c88:	00034403          	lbu	s0,0(t1)
    3c8c:	fc040ce3          	beqz	s0,3c64 <bsp_printf+0x6c>
                    if (format[i] == 'c') {
    3c90:	fa840593          	addi	a1,s0,-88
    3c94:	0ff5f813          	zext.b	a6,a1
    3c98:	ff0f64e3          	bltu	t5,a6,3c80 <bsp_printf+0x88>
    3c9c:	00281f93          	slli	t6,a6,0x2
    3ca0:	01df87b3          	add	a5,t6,t4
    3ca4:	0007a683          	lw	a3,0(a5) # 2000 <_malloc_r+0x740>
    3ca8:	00068067          	jr	a3
                        bsp_printf_x(va_arg(ap,int));
    3cac:	00c12283          	lw	t0,12(sp)
        return *((volatile u32*) address);
    3cb0:	f8010337          	lui	t1,0xf8010
    3cb4:	000065b7          	lui	a1,0x6
    3cb8:	00428393          	addi	t2,t0,4
        bsp_printHex_lower(val);
    3cbc:	0002a403          	lw	s0,0(t0)
                        bsp_printf_x(va_arg(ap,int));
    3cc0:	00712623          	sw	t2,12(sp)
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    3cc4:	01c00813          	li	a6,28
    3cc8:	c6458f93          	addi	t6,a1,-924 # 5c64 <_data+0x4c>
    3ccc:	f80103b7          	lui	t2,0xf8010
    3cd0:	00430693          	addi	a3,t1,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3cd4:	ffc00293          	li	t0,-4
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    3cd8:	010457b3          	srl	a5,s0,a6
    3cdc:	00f7f313          	andi	t1,a5,15
    3ce0:	006f85b3          	add	a1,t6,t1
    3ce4:	0005c303          	lbu	t1,0(a1)
    3ce8:	0006a783          	lw	a5,0(a3)
    3cec:	0107d593          	srli	a1,a5,0x10
    3cf0:	0ff5f793          	zext.b	a5,a1
    3cf4:	fe078ae3          	beqz	a5,3ce8 <bsp_printf+0xf0>
        *((volatile u32*) address) = data;
    3cf8:	0063a023          	sw	t1,0(t2) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    3cfc:	ffc80813          	addi	a6,a6,-4
    3d00:	fc581ce3          	bne	a6,t0,3cd8 <bsp_printf+0xe0>
    3d04:	f61ff06f          	j	3c64 <bsp_printf+0x6c>
                        bsp_printf_s(va_arg(ap,char*));
    3d08:	00c12403          	lw	s0,12(sp)
    3d0c:	00042803          	lw	a6,0(s0)
    3d10:	00440f93          	addi	t6,s0,4
    3d14:	01f12623          	sw	t6,12(sp)
        while (*p)
    3d18:	00084303          	lbu	t1,0(a6)
    3d1c:	f40304e3          	beqz	t1,3c64 <bsp_printf+0x6c>
        return *((volatile u32*) address);
    3d20:	f80103b7          	lui	t2,0xf8010
    3d24:	f80102b7          	lui	t0,0xf8010
    3d28:	00438693          	addi	a3,t2,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
            _putchar(*(p++));
    3d2c:	00180813          	addi	a6,a6,1
    3d30:	0006a583          	lw	a1,0(a3)
    3d34:	0105d793          	srli	a5,a1,0x10
    3d38:	0ff7f413          	zext.b	s0,a5
    3d3c:	fe040ae3          	beqz	s0,3d30 <bsp_printf+0x138>
        *((volatile u32*) address) = data;
    3d40:	0062a023          	sw	t1,0(t0) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        while (*p)
    3d44:	00084303          	lbu	t1,0(a6)
    3d48:	fe0312e3          	bnez	t1,3d2c <bsp_printf+0x134>
    3d4c:	f19ff06f          	j	3c64 <bsp_printf+0x6c>
                        bsp_printf_d(va_arg(ap,int));
    3d50:	00c12383          	lw	t2,12(sp)
    3d54:	0003a783          	lw	a5,0(t2)
    3d58:	00438f93          	addi	t6,t2,4
    3d5c:	01f12623          	sw	t6,12(sp)
        if (val < 0) {
    3d60:	1207c863          	bltz	a5,3e90 <bsp_printf+0x298>
        for (i = 0; format[i]; i++)
    3d64:	01010313          	addi	t1,sp,16
    3d68:	00030693          	mv	a3,t1
            *(p++) = '0' + val % 10;
    3d6c:	00a00293          	li	t0,10
        while (val || p == buffer) {
    3d70:	00079463          	bnez	a5,3d78 <bsp_printf+0x180>
    3d74:	0a669863          	bne	a3,t1,3e24 <bsp_printf+0x22c>
            *(p++) = '0' + val % 10;
    3d78:	0257e5b3          	rem	a1,a5,t0
    3d7c:	00168693          	addi	a3,a3,1
    3d80:	03058f93          	addi	t6,a1,48
            val = val / 10;
    3d84:	0257c7b3          	div	a5,a5,t0
            *(p++) = '0' + val % 10;
    3d88:	fff68fa3          	sb	t6,-1(a3)
            val = val / 10;
    3d8c:	fe5ff06f          	j	3d70 <bsp_printf+0x178>
                        bsp_printf_c(va_arg(ap,int));
    3d90:	00c12403          	lw	s0,12(sp)
        return *((volatile u32*) address);
    3d94:	f80106b7          	lui	a3,0xf8010
    3d98:	00468313          	addi	t1,a3,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3d9c:	00042803          	lw	a6,0(s0)
    3da0:	00440393          	addi	t2,s0,4
    3da4:	00712623          	sw	t2,12(sp)
    3da8:	00032283          	lw	t0,0(t1)
    3dac:	0102d593          	srli	a1,t0,0x10
    3db0:	0ff5f793          	zext.b	a5,a1
    3db4:	fe078ae3          	beqz	a5,3da8 <bsp_printf+0x1b0>
        write_u32(data, reg + UART_DATA);
    3db8:	0ff87f93          	zext.b	t6,a6
        *((volatile u32*) address) = data;
    3dbc:	f8010437          	lui	s0,0xf8010
    3dc0:	01f42023          	sw	t6,0(s0) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
    }
    3dc4:	ea1ff06f          	j	3c64 <bsp_printf+0x6c>
                        bsp_printf_X(va_arg(ap,int));
    3dc8:	00c12803          	lw	a6,12(sp)
        return *((volatile u32*) address);
    3dcc:	f80106b7          	lui	a3,0xf8010
    3dd0:	00006337          	lui	t1,0x6
    3dd4:	00480393          	addi	t2,a6,4
            bsp_printHex(val);
    3dd8:	00082403          	lw	s0,0(a6)
                        bsp_printf_X(va_arg(ap,int));
    3ddc:	00712623          	sw	t2,12(sp)
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    3de0:	01c00813          	li	a6,28
    3de4:	c7830f93          	addi	t6,t1,-904 # 5c78 <_data+0x60>
    3de8:	f80103b7          	lui	t2,0xf8010
    3dec:	00468693          	addi	a3,a3,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3df0:	ffc00293          	li	t0,-4
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    3df4:	010455b3          	srl	a1,s0,a6
    3df8:	00f5f793          	andi	a5,a1,15
    3dfc:	00ff8333          	add	t1,t6,a5
    3e00:	00034303          	lbu	t1,0(t1)
    3e04:	0006a583          	lw	a1,0(a3)
        while(uart_writeAvailability(reg) == 0);
    3e08:	0105d793          	srli	a5,a1,0x10
    3e0c:	0ff7f593          	zext.b	a1,a5
    3e10:	fe058ae3          	beqz	a1,3e04 <bsp_printf+0x20c>
        *((volatile u32*) address) = data;
    3e14:	0063a023          	sw	t1,0(t2) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    3e18:	ffc80813          	addi	a6,a6,-4
    3e1c:	fc581ce3          	bne	a6,t0,3df4 <bsp_printf+0x1fc>
    3e20:	e45ff06f          	j	3c64 <bsp_printf+0x6c>
        return *((volatile u32*) address);
    3e24:	f80107b7          	lui	a5,0xf8010
    3e28:	f80102b7          	lui	t0,0xf8010
    3e2c:	00478593          	addi	a1,a5,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
            bsp_printf_c(*(--p));
    3e30:	fff6cf83          	lbu	t6,-1(a3)
    3e34:	fff68693          	addi	a3,a3,-1
    3e38:	0005a803          	lw	a6,0(a1)
    3e3c:	01085413          	srli	s0,a6,0x10
    3e40:	0ff47393          	zext.b	t2,s0
    3e44:	fe038ae3          	beqz	t2,3e38 <bsp_printf+0x240>
        *((volatile u32*) address) = data;
    3e48:	01f2a023          	sw	t6,0(t0) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        while (p != buffer)
    3e4c:	fe6692e3          	bne	a3,t1,3e30 <bsp_printf+0x238>
    3e50:	e15ff06f          	j	3c64 <bsp_printf+0x6c>
        return *((volatile u32*) address);
    3e54:	f80103b7          	lui	t2,0xf8010
                while (format[++i]) {
    3e58:	00006fb7          	lui	t6,0x6
    3e5c:	03c00313          	li	t1,60
    3e60:	c18f8813          	addi	a6,t6,-1000 # 5c18 <_data>
    3e64:	f80102b7          	lui	t0,0xf8010
    3e68:	00438693          	addi	a3,t2,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
            _putchar(*(p++));
    3e6c:	00180813          	addi	a6,a6,1
    3e70:	0006a583          	lw	a1,0(a3)
    3e74:	0105d793          	srli	a5,a1,0x10
    3e78:	0ff7f413          	zext.b	s0,a5
    3e7c:	fe040ae3          	beqz	s0,3e70 <bsp_printf+0x278>
        *((volatile u32*) address) = data;
    3e80:	0062a023          	sw	t1,0(t0) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
        while (*p)
    3e84:	00084303          	lbu	t1,0(a6)
    3e88:	fe0312e3          	bnez	t1,3e6c <bsp_printf+0x274>
    3e8c:	dd9ff06f          	j	3c64 <bsp_printf+0x6c>
        return *((volatile u32*) address);
    3e90:	f80102b7          	lui	t0,0xf8010
    3e94:	00428593          	addi	a1,t0,4 # f8010004 <__freertos_irq_stack_top+0xf8007a84>
    3e98:	0005a683          	lw	a3,0(a1)
    3e9c:	0106d813          	srli	a6,a3,0x10
    3ea0:	0ff87413          	zext.b	s0,a6
    3ea4:	fe040ae3          	beqz	s0,3e98 <bsp_printf+0x2a0>
        *((volatile u32*) address) = data;
    3ea8:	f8010337          	lui	t1,0xf8010
    3eac:	02d00393          	li	t2,45
    3eb0:	00732023          	sw	t2,0(t1) # f8010000 <__freertos_irq_stack_top+0xf8007a80>
            val = -val;
    3eb4:	40f007b3          	neg	a5,a5
    3eb8:	eadff06f          	j	3d64 <bsp_printf+0x16c>

00003ebc <style_multistyle_hash>:
{
    const uint8_t *p;
    uint32_t h = 0x811C9DC5u;
    uint32_t i;

    if (entry == 0) {
    3ebc:	16050663          	beqz	a0,4028 <style_multistyle_hash+0x16c>
{
    3ec0:	ff010113          	addi	sp,sp,-16
    3ec4:	00812423          	sw	s0,8(sp)
        return 0u;
    }

    p = (const uint8_t *)entry->model_base;
    3ec8:	00852403          	lw	s0,8(a0)
    style_net_cache_invalidate(p, entry->model_bytes);
    3ecc:	01052583          	lw	a1,16(a0)
{
    3ed0:	00912223          	sw	s1,4(sp)
    3ed4:	00050493          	mv	s1,a0
    style_net_cache_invalidate(p, entry->model_bytes);
    3ed8:	00040513          	mv	a0,s0
{
    3edc:	00112623          	sw	ra,12(sp)
    style_net_cache_invalidate(p, entry->model_bytes);
    3ee0:	13d010ef          	jal	581c <style_net_cache_invalidate>
    for (i = 0u; i < entry->model_bytes; ++i) {
    3ee4:	0104a703          	lw	a4,16(s1)
    uint32_t h = 0x811C9DC5u;
    3ee8:	811ca537          	lui	a0,0x811ca
    for (i = 0u; i < entry->model_bytes; ++i) {
    3eec:	14070263          	beqz	a4,4030 <style_multistyle_hash+0x174>
        h ^= p[i];
        h *= 0x01000193u;
    3ef0:	010007b7          	lui	a5,0x1000
    3ef4:	00777693          	andi	a3,a4,7
    3ef8:	008700b3          	add	ra,a4,s0
    uint32_t h = 0x811C9DC5u;
    3efc:	dc550513          	addi	a0,a0,-571 # 811c9dc5 <__freertos_irq_stack_top+0x811c1845>
        h *= 0x01000193u;
    3f00:	19378293          	addi	t0,a5,403 # 1000193 <__freertos_irq_stack_top+0xff7c13>
    3f04:	0a068463          	beqz	a3,3fac <style_multistyle_hash+0xf0>
    3f08:	00100613          	li	a2,1
    3f0c:	08c68663          	beq	a3,a2,3f98 <style_multistyle_hash+0xdc>
    3f10:	00200313          	li	t1,2
    3f14:	06668a63          	beq	a3,t1,3f88 <style_multistyle_hash+0xcc>
    3f18:	00300393          	li	t2,3
    3f1c:	04768e63          	beq	a3,t2,3f78 <style_multistyle_hash+0xbc>
    3f20:	00400593          	li	a1,4
    3f24:	04b68263          	beq	a3,a1,3f68 <style_multistyle_hash+0xac>
    3f28:	00500813          	li	a6,5
    3f2c:	03068663          	beq	a3,a6,3f58 <style_multistyle_hash+0x9c>
    3f30:	00600893          	li	a7,6
    3f34:	01168a63          	beq	a3,a7,3f48 <style_multistyle_hash+0x8c>
        h ^= p[i];
    3f38:	00044e03          	lbu	t3,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    3f3c:	00140413          	addi	s0,s0,1
        h ^= p[i];
    3f40:	00ae4eb3          	xor	t4,t3,a0
        h *= 0x01000193u;
    3f44:	025e8533          	mul	a0,t4,t0
        h ^= p[i];
    3f48:	00044f03          	lbu	t5,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    3f4c:	00140413          	addi	s0,s0,1
        h ^= p[i];
    3f50:	00af4fb3          	xor	t6,t5,a0
        h *= 0x01000193u;
    3f54:	025f8533          	mul	a0,t6,t0
        h ^= p[i];
    3f58:	00044483          	lbu	s1,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    3f5c:	00140413          	addi	s0,s0,1
        h ^= p[i];
    3f60:	00a4c733          	xor	a4,s1,a0
        h *= 0x01000193u;
    3f64:	02570533          	mul	a0,a4,t0
        h ^= p[i];
    3f68:	00044783          	lbu	a5,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    3f6c:	00140413          	addi	s0,s0,1
        h ^= p[i];
    3f70:	00a7c533          	xor	a0,a5,a0
        h *= 0x01000193u;
    3f74:	02550533          	mul	a0,a0,t0
        h ^= p[i];
    3f78:	00044683          	lbu	a3,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    3f7c:	00140413          	addi	s0,s0,1
        h ^= p[i];
    3f80:	00a6c633          	xor	a2,a3,a0
        h *= 0x01000193u;
    3f84:	02560533          	mul	a0,a2,t0
        h ^= p[i];
    3f88:	00044303          	lbu	t1,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    3f8c:	00140413          	addi	s0,s0,1
        h ^= p[i];
    3f90:	00a343b3          	xor	t2,t1,a0
        h *= 0x01000193u;
    3f94:	02538533          	mul	a0,t2,t0
        h ^= p[i];
    3f98:	00044583          	lbu	a1,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    3f9c:	00140413          	addi	s0,s0,1
        h ^= p[i];
    3fa0:	00a5c833          	xor	a6,a1,a0
        h *= 0x01000193u;
    3fa4:	02580533          	mul	a0,a6,t0
    for (i = 0u; i < entry->model_bytes; ++i) {
    3fa8:	06808663          	beq	ra,s0,4014 <style_multistyle_hash+0x158>
        h ^= p[i];
    3fac:	00044e03          	lbu	t3,0(s0)
    3fb0:	00144e83          	lbu	t4,1(s0)
    3fb4:	00244883          	lbu	a7,2(s0)
    3fb8:	00ae4f33          	xor	t5,t3,a0
    3fbc:	00344483          	lbu	s1,3(s0)
    3fc0:	00444703          	lbu	a4,4(s0)
    3fc4:	00544783          	lbu	a5,5(s0)
    3fc8:	00644683          	lbu	a3,6(s0)
        h *= 0x01000193u;
    3fcc:	025f0fb3          	mul	t6,t5,t0
        h ^= p[i];
    3fd0:	00744503          	lbu	a0,7(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    3fd4:	00840413          	addi	s0,s0,8
        h ^= p[i];
    3fd8:	01fec633          	xor	a2,t4,t6
        h *= 0x01000193u;
    3fdc:	02560333          	mul	t1,a2,t0
        h ^= p[i];
    3fe0:	0068c3b3          	xor	t2,a7,t1
        h *= 0x01000193u;
    3fe4:	025385b3          	mul	a1,t2,t0
        h ^= p[i];
    3fe8:	00b4c833          	xor	a6,s1,a1
        h *= 0x01000193u;
    3fec:	02580e33          	mul	t3,a6,t0
        h ^= p[i];
    3ff0:	01c74eb3          	xor	t4,a4,t3
        h *= 0x01000193u;
    3ff4:	025e88b3          	mul	a7,t4,t0
        h ^= p[i];
    3ff8:	0117cf33          	xor	t5,a5,a7
        h *= 0x01000193u;
    3ffc:	025f0fb3          	mul	t6,t5,t0
        h ^= p[i];
    4000:	01f6c4b3          	xor	s1,a3,t6
        h *= 0x01000193u;
    4004:	02548733          	mul	a4,s1,t0
        h ^= p[i];
    4008:	00e547b3          	xor	a5,a0,a4
        h *= 0x01000193u;
    400c:	02578533          	mul	a0,a5,t0
    for (i = 0u; i < entry->model_bytes; ++i) {
    4010:	f8809ee3          	bne	ra,s0,3fac <style_multistyle_hash+0xf0>
    }
    return h;
}
    4014:	00c12083          	lw	ra,12(sp)
    4018:	00812403          	lw	s0,8(sp)
    401c:	00412483          	lw	s1,4(sp)
    4020:	01010113          	addi	sp,sp,16
    4024:	00008067          	ret
        return 0u;
    4028:	00000513          	li	a0,0
}
    402c:	00008067          	ret
    uint32_t h = 0x811C9DC5u;
    4030:	dc550513          	addi	a0,a0,-571
    4034:	fe1ff06f          	j	4014 <style_multistyle_hash+0x158>

00004038 <style_multistyle_verify>:

int style_multistyle_verify(const style_multistyle_entry_t *entry)
{
    if (entry == 0) {
    4038:	18050463          	beqz	a0,41c0 <style_multistyle_verify+0x188>
{
    403c:	ff010113          	addi	sp,sp,-16
    4040:	00812423          	sw	s0,8(sp)
    p = (const uint8_t *)entry->model_base;
    4044:	00852403          	lw	s0,8(a0)
    style_net_cache_invalidate(p, entry->model_bytes);
    4048:	01052583          	lw	a1,16(a0)
{
    404c:	00912223          	sw	s1,4(sp)
    4050:	00050493          	mv	s1,a0
    style_net_cache_invalidate(p, entry->model_bytes);
    4054:	00040513          	mv	a0,s0
{
    4058:	00112623          	sw	ra,12(sp)
    style_net_cache_invalidate(p, entry->model_bytes);
    405c:	7c0010ef          	jal	581c <style_net_cache_invalidate>
    for (i = 0u; i < entry->model_bytes; ++i) {
    4060:	0104a683          	lw	a3,16(s1)
    uint32_t h = 0x811C9DC5u;
    4064:	811ca7b7          	lui	a5,0x811ca
    for (i = 0u; i < entry->model_bytes; ++i) {
    4068:	14068863          	beqz	a3,41b8 <style_multistyle_verify+0x180>
        h *= 0x01000193u;
    406c:	01000737          	lui	a4,0x1000
    4070:	0076f613          	andi	a2,a3,7
    4074:	00d400b3          	add	ra,s0,a3
    uint32_t h = 0x811C9DC5u;
    4078:	dc578e93          	addi	t4,a5,-571 # 811c9dc5 <__freertos_irq_stack_top+0x811c1845>
        h *= 0x01000193u;
    407c:	19370293          	addi	t0,a4,403 # 1000193 <__freertos_irq_stack_top+0xff7c13>
    4080:	08060c63          	beqz	a2,4118 <style_multistyle_verify+0xe0>
    4084:	00100593          	li	a1,1
    4088:	06b60e63          	beq	a2,a1,4104 <style_multistyle_verify+0xcc>
    408c:	00200313          	li	t1,2
    4090:	06660263          	beq	a2,t1,40f4 <style_multistyle_verify+0xbc>
    4094:	00300393          	li	t2,3
    4098:	04760663          	beq	a2,t2,40e4 <style_multistyle_verify+0xac>
    409c:	00400513          	li	a0,4
    40a0:	02a60a63          	beq	a2,a0,40d4 <style_multistyle_verify+0x9c>
    40a4:	00500813          	li	a6,5
    40a8:	01060e63          	beq	a2,a6,40c4 <style_multistyle_verify+0x8c>
    40ac:	00600893          	li	a7,6
    40b0:	0f161a63          	bne	a2,a7,41a4 <style_multistyle_verify+0x16c>
        h ^= p[i];
    40b4:	00044f03          	lbu	t5,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    40b8:	00140413          	addi	s0,s0,1
        h ^= p[i];
    40bc:	01df4fb3          	xor	t6,t5,t4
        h *= 0x01000193u;
    40c0:	025f8eb3          	mul	t4,t6,t0
        h ^= p[i];
    40c4:	00044683          	lbu	a3,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    40c8:	00140413          	addi	s0,s0,1
        h ^= p[i];
    40cc:	01d6c7b3          	xor	a5,a3,t4
        h *= 0x01000193u;
    40d0:	02578eb3          	mul	t4,a5,t0
        h ^= p[i];
    40d4:	00044703          	lbu	a4,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    40d8:	00140413          	addi	s0,s0,1
        h ^= p[i];
    40dc:	01d74633          	xor	a2,a4,t4
        h *= 0x01000193u;
    40e0:	02560eb3          	mul	t4,a2,t0
        h ^= p[i];
    40e4:	00044583          	lbu	a1,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    40e8:	00140413          	addi	s0,s0,1
        h ^= p[i];
    40ec:	01d5c333          	xor	t1,a1,t4
        h *= 0x01000193u;
    40f0:	02530eb3          	mul	t4,t1,t0
        h ^= p[i];
    40f4:	00044383          	lbu	t2,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    40f8:	00140413          	addi	s0,s0,1
        h ^= p[i];
    40fc:	01d3c533          	xor	a0,t2,t4
        h *= 0x01000193u;
    4100:	02550eb3          	mul	t4,a0,t0
        h ^= p[i];
    4104:	00044803          	lbu	a6,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    4108:	00140413          	addi	s0,s0,1
        h ^= p[i];
    410c:	01d848b3          	xor	a7,a6,t4
        h *= 0x01000193u;
    4110:	02588eb3          	mul	t4,a7,t0
    for (i = 0u; i < entry->model_bytes; ++i) {
    4114:	06140663          	beq	s0,ra,4180 <style_multistyle_verify+0x148>
        h ^= p[i];
    4118:	00044e03          	lbu	t3,0(s0)
    411c:	00144f03          	lbu	t5,1(s0)
    4120:	00244f83          	lbu	t6,2(s0)
    4124:	01de46b3          	xor	a3,t3,t4
    4128:	00344383          	lbu	t2,3(s0)
    412c:	00444503          	lbu	a0,4(s0)
    4130:	00544583          	lbu	a1,5(s0)
    4134:	00644603          	lbu	a2,6(s0)
        h *= 0x01000193u;
    4138:	02568733          	mul	a4,a3,t0
        h ^= p[i];
    413c:	00744783          	lbu	a5,7(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    4140:	00840413          	addi	s0,s0,8
        h ^= p[i];
    4144:	00ef4333          	xor	t1,t5,a4
        h *= 0x01000193u;
    4148:	02530833          	mul	a6,t1,t0
        h ^= p[i];
    414c:	010fc8b3          	xor	a7,t6,a6
        h *= 0x01000193u;
    4150:	02588eb3          	mul	t4,a7,t0
        h ^= p[i];
    4154:	01d3ce33          	xor	t3,t2,t4
        h *= 0x01000193u;
    4158:	025e0f33          	mul	t5,t3,t0
        h ^= p[i];
    415c:	01e54fb3          	xor	t6,a0,t5
        h *= 0x01000193u;
    4160:	025f86b3          	mul	a3,t6,t0
        h ^= p[i];
    4164:	00d5c733          	xor	a4,a1,a3
        h *= 0x01000193u;
    4168:	025703b3          	mul	t2,a4,t0
        h ^= p[i];
    416c:	00764533          	xor	a0,a2,t2
        h *= 0x01000193u;
    4170:	025505b3          	mul	a1,a0,t0
        h ^= p[i];
    4174:	00b7c633          	xor	a2,a5,a1
        h *= 0x01000193u;
    4178:	02560eb3          	mul	t4,a2,t0
    for (i = 0u; i < entry->model_bytes; ++i) {
    417c:	f8141ee3          	bne	s0,ra,4118 <style_multistyle_verify+0xe0>
        return -1;
    }
    return (style_multistyle_hash(entry) == entry->fnv1a32) ? 0 : -1;
    4180:	0144a483          	lw	s1,20(s1)
}
    4184:	00812403          	lw	s0,8(sp)
    return (style_multistyle_hash(entry) == entry->fnv1a32) ? 0 : -1;
    4188:	41d480b3          	sub	ra,s1,t4
    418c:	001032b3          	snez	t0,ra
}
    4190:	00c12083          	lw	ra,12(sp)
    4194:	00412483          	lw	s1,4(sp)
    return (style_multistyle_hash(entry) == entry->fnv1a32) ? 0 : -1;
    4198:	40500533          	neg	a0,t0
}
    419c:	01010113          	addi	sp,sp,16
    41a0:	00008067          	ret
        h ^= p[i];
    41a4:	00044e03          	lbu	t3,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    41a8:	00140413          	addi	s0,s0,1
        h ^= p[i];
    41ac:	01de4eb3          	xor	t4,t3,t4
        h *= 0x01000193u;
    41b0:	025e8eb3          	mul	t4,t4,t0
    for (i = 0u; i < entry->model_bytes; ++i) {
    41b4:	f01ff06f          	j	40b4 <style_multistyle_verify+0x7c>
    uint32_t h = 0x811C9DC5u;
    41b8:	dc578e93          	addi	t4,a5,-571
    41bc:	fc5ff06f          	j	4180 <style_multistyle_verify+0x148>
        return -1;
    41c0:	fff00513          	li	a0,-1
}
    41c4:	00008067          	ret

000041c8 <style_multistyle_prepare>:

int style_multistyle_prepare(void)
{
    41c8:	fd010113          	addi	sp,sp,-48
    41cc:	01312e23          	sw	s3,28(sp)
    41d0:	000069b7          	lui	s3,0x6
    41d4:	02912223          	sw	s1,36(sp)
    41d8:	01412c23          	sw	s4,24(sp)
    41dc:	01712623          	sw	s7,12(sp)
    uint32_t h = 0x811C9DC5u;
    41e0:	811caa37          	lui	s4,0x811ca
    41e4:	5f498b93          	addi	s7,s3,1524 # 65f4 <style_multistyle_entries>
        h *= 0x01000193u;
    41e8:	010004b7          	lui	s1,0x1000
{
    41ec:	03212023          	sw	s2,32(sp)
    41f0:	02112623          	sw	ra,44(sp)
    41f4:	02812423          	sw	s0,40(sp)
    41f8:	01512a23          	sw	s5,20(sp)
    41fc:	048b8913          	addi	s2,s7,72
    4200:	5f498993          	addi	s3,s3,1524
    uint32_t h = 0x811C9DC5u;
    4204:	dc5a0a13          	addi	s4,s4,-571 # 811c9dc5 <__freertos_irq_stack_top+0x811c1845>
        h *= 0x01000193u;
    4208:	19348493          	addi	s1,s1,403 # 1000193 <__freertos_irq_stack_top+0xff7c13>
    style_net_cache_invalidate(p, entry->model_bytes);
    420c:	0109aa83          	lw	s5,16(s3)
    p = (const uint8_t *)entry->model_base;
    4210:	0089a403          	lw	s0,8(s3)
    style_net_cache_invalidate(p, entry->model_bytes);
    4214:	000a8593          	mv	a1,s5
    4218:	00040513          	mv	a0,s0
    421c:	600010ef          	jal	581c <style_net_cache_invalidate>
    for (i = 0u; i < entry->model_bytes; ++i) {
    4220:	620a8463          	beqz	s5,4848 <style_multistyle_prepare+0x680>
    4224:	007af693          	andi	a3,s5,7
    4228:	01540733          	add	a4,s0,s5
    uint32_t h = 0x811C9DC5u;
    422c:	000a0593          	mv	a1,s4
    4230:	08068c63          	beqz	a3,42c8 <style_multistyle_prepare+0x100>
    4234:	00100613          	li	a2,1
    4238:	06c68e63          	beq	a3,a2,42b4 <style_multistyle_prepare+0xec>
    423c:	00200093          	li	ra,2
    4240:	06168263          	beq	a3,ra,42a4 <style_multistyle_prepare+0xdc>
    4244:	00300293          	li	t0,3
    4248:	04568663          	beq	a3,t0,4294 <style_multistyle_prepare+0xcc>
    424c:	00400313          	li	t1,4
    4250:	02668a63          	beq	a3,t1,4284 <style_multistyle_prepare+0xbc>
    4254:	00500393          	li	t2,5
    4258:	00768e63          	beq	a3,t2,4274 <style_multistyle_prepare+0xac>
    425c:	00600513          	li	a0,6
    4260:	10a69663          	bne	a3,a0,436c <style_multistyle_prepare+0x1a4>
        h ^= p[i];
    4264:	00044883          	lbu	a7,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    4268:	00140413          	addi	s0,s0,1
        h ^= p[i];
    426c:	00b8ce33          	xor	t3,a7,a1
        h *= 0x01000193u;
    4270:	029e05b3          	mul	a1,t3,s1
        h ^= p[i];
    4274:	00044e83          	lbu	t4,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    4278:	00140413          	addi	s0,s0,1
        h ^= p[i];
    427c:	00becf33          	xor	t5,t4,a1
        h *= 0x01000193u;
    4280:	029f05b3          	mul	a1,t5,s1
        h ^= p[i];
    4284:	00044f83          	lbu	t6,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    4288:	00140413          	addi	s0,s0,1
        h ^= p[i];
    428c:	00bfcab3          	xor	s5,t6,a1
        h *= 0x01000193u;
    4290:	029a85b3          	mul	a1,s5,s1
        h ^= p[i];
    4294:	00044683          	lbu	a3,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    4298:	00140413          	addi	s0,s0,1
        h ^= p[i];
    429c:	00b6c7b3          	xor	a5,a3,a1
        h *= 0x01000193u;
    42a0:	029785b3          	mul	a1,a5,s1
        h ^= p[i];
    42a4:	00044603          	lbu	a2,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    42a8:	00140413          	addi	s0,s0,1
        h ^= p[i];
    42ac:	00b640b3          	xor	ra,a2,a1
        h *= 0x01000193u;
    42b0:	029085b3          	mul	a1,ra,s1
        h ^= p[i];
    42b4:	00044283          	lbu	t0,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    42b8:	00140413          	addi	s0,s0,1
        h ^= p[i];
    42bc:	00b2c333          	xor	t1,t0,a1
        h *= 0x01000193u;
    42c0:	029305b3          	mul	a1,t1,s1
    for (i = 0u; i < entry->model_bytes; ++i) {
    42c4:	06870663          	beq	a4,s0,4330 <style_multistyle_prepare+0x168>
        h ^= p[i];
    42c8:	00044383          	lbu	t2,0(s0)
    42cc:	00144883          	lbu	a7,1(s0)
    42d0:	00244803          	lbu	a6,2(s0)
    42d4:	00b3c533          	xor	a0,t2,a1
    42d8:	00344e83          	lbu	t4,3(s0)
    42dc:	00444f03          	lbu	t5,4(s0)
    42e0:	00544f83          	lbu	t6,5(s0)
    42e4:	00644a83          	lbu	s5,6(s0)
        h *= 0x01000193u;
    42e8:	02950e33          	mul	t3,a0,s1
        h ^= p[i];
    42ec:	00744783          	lbu	a5,7(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    42f0:	00840413          	addi	s0,s0,8
        h ^= p[i];
    42f4:	01c8c6b3          	xor	a3,a7,t3
        h *= 0x01000193u;
    42f8:	02968633          	mul	a2,a3,s1
        h ^= p[i];
    42fc:	00c840b3          	xor	ra,a6,a2
        h *= 0x01000193u;
    4300:	029082b3          	mul	t0,ra,s1
        h ^= p[i];
    4304:	005ec333          	xor	t1,t4,t0
        h *= 0x01000193u;
    4308:	029305b3          	mul	a1,t1,s1
        h ^= p[i];
    430c:	00bf43b3          	xor	t2,t5,a1
        h *= 0x01000193u;
    4310:	029388b3          	mul	a7,t2,s1
        h ^= p[i];
    4314:	011fc833          	xor	a6,t6,a7
        h *= 0x01000193u;
    4318:	02980533          	mul	a0,a6,s1
        h ^= p[i];
    431c:	00aace33          	xor	t3,s5,a0
        h *= 0x01000193u;
    4320:	029e0eb3          	mul	t4,t3,s1
        h ^= p[i];
    4324:	01d7cf33          	xor	t5,a5,t4
        h *= 0x01000193u;
    4328:	029f05b3          	mul	a1,t5,s1
    for (i = 0u; i < entry->model_bytes; ++i) {
    432c:	f8871ee3          	bne	a4,s0,42c8 <style_multistyle_prepare+0x100>
    return (style_multistyle_hash(entry) == entry->fnv1a32) ? 0 : -1;
    4330:	0149a703          	lw	a4,20(s3)
    4334:	04b71663          	bne	a4,a1,4380 <style_multistyle_prepare+0x1b8>
    unsigned i;
    int missing = 0;

    for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
    4338:	01898993          	addi	s3,s3,24
    433c:	ed2998e3          	bne	s3,s2,420c <style_multistyle_prepare+0x44>
        bsp_printf("style model %s: flash 0x%x -> DDR 0x%x\r\n",
                   entry->name, (unsigned)entry->flash_base,
                   (unsigned)entry->model_base);
    }
    return 0;
}
    4340:	02c12083          	lw	ra,44(sp)
    4344:	02812403          	lw	s0,40(sp)
    4348:	02412483          	lw	s1,36(sp)
    434c:	02012903          	lw	s2,32(sp)
    4350:	01c12983          	lw	s3,28(sp)
    4354:	01812a03          	lw	s4,24(sp)
    4358:	01412a83          	lw	s5,20(sp)
    435c:	00c12b83          	lw	s7,12(sp)
    4360:	00000513          	li	a0,0
    4364:	03010113          	addi	sp,sp,48
    4368:	00008067          	ret
        h ^= p[i];
    436c:	00044583          	lbu	a1,0(s0)
    for (i = 0u; i < entry->model_bytes; ++i) {
    4370:	00140413          	addi	s0,s0,1
        h ^= p[i];
    4374:	0145c833          	xor	a6,a1,s4
        h *= 0x01000193u;
    4378:	029805b3          	mul	a1,a6,s1
    for (i = 0u; i < entry->model_bytes; ++i) {
    437c:	ee9ff06f          	j	4264 <style_multistyle_prepare+0x9c>
    4380:	01612823          	sw	s6,16(sp)
    bsp_printf("loading style models from flash...\r\n");
    4384:	00006b37          	lui	s6,0x6
    4388:	01812423          	sw	s8,8(sp)
    438c:	2f4b0513          	addi	a0,s6,756 # 62f4 <_data+0x6dc>
    4390:	f8014c37          	lui	s8,0xf8014
    4394:	865ff0ef          	jal	3bf8 <bsp_printf>
    4398:	00200a13          	li	s4,2
    439c:	000c2423          	sw	zero,8(s8) # f8014008 <__freertos_irq_stack_top+0xf800ba88>
    43a0:	f80149b7          	lui	s3,0xf8014
    43a4:	0349a023          	sw	s4,32(s3) # f8014020 <__freertos_irq_stack_top+0xf800baa0>
    43a8:	f80144b7          	lui	s1,0xf8014
    43ac:	00500f93          	li	t6,5
    43b0:	03f4a223          	sw	t6,36(s1) # f8014024 <__freertos_irq_stack_top+0xf800baa4>
    43b4:	f8014437          	lui	s0,0xf8014
    43b8:	03442423          	sw	s4,40(s0) # f8014028 <__freertos_irq_stack_top+0xf800baa8>
    43bc:	f8014ab7          	lui	s5,0xf8014
    43c0:	00700693          	li	a3,7
        return *((volatile u32*) address);
    43c4:	f8b0c7b7          	lui	a5,0xf8b0c
        *((volatile u32*) address) = data;
    43c8:	02daa623          	sw	a3,44(s5) # f801402c <__freertos_irq_stack_top+0xf800baac>
        return *((volatile u32*) address);
    43cc:	ff87a603          	lw	a2,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8b03a78>
    43d0:	ff878293          	addi	t0,a5,-8
*          not yet elapsed.
*
******************************************************************************/
    static void clint_uDelay(u32 usec, u32 hz, u32 reg){
        u32 mTimePerUsec = hz/1000000;
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    43d4:	06460313          	addi	t1,a2,100
    43d8:	0002a083          	lw	ra,0(t0)
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    43dc:	401305b3          	sub	a1,t1,ra
    43e0:	fe05dce3          	bgez	a1,43d8 <style_multistyle_prepare+0x210>
    43e4:	f80143b7          	lui	t2,0xf8014
 *
 * @return The availability of command buffer space (lower 16 bits of SPI buffer)
 *
 ******************************************************************************/
    static u32 spi_cmdAvailability(u32 reg){
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    43e8:	00010837          	lui	a6,0x10
    43ec:	00438893          	addi	a7,t2,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    43f0:	fff80513          	addi	a0,a6,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
#ifdef SYSTEM_SPI_2_IO_CTRL
    	if(reg == SYSTEM_SPI_2_IO_CTRL) cmdFifo_depth = SYSTEM_SPI_2_IO_PARAMETER_CMD_FIFO_DEPTH;
#endif

    	bsp_uDelay(1);
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    43f4:	10000e13          	li	t3,256
    43f8:	0008ae83          	lw	t4,0(a7)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    43fc:	00aeff33          	and	t5,t4,a0
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    4400:	ffcf1ce3          	bne	t5,t3,43f8 <style_multistyle_prepare+0x230>
    4404:	f8014737          	lui	a4,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4408:	00010c37          	lui	s8,0x10
    440c:	00470b13          	addi	s6,a4,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4410:	fffc0993          	addi	s3,s8,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    4414:	000b2a03          	lw	s4,0(s6)
    4418:	013a74b3          	and	s1,s4,s3
        while(spi_cmdAvailability(reg) == 0);
    441c:	fe048ce3          	beqz	s1,4414 <style_multistyle_prepare+0x24c>
        *((volatile u32*) address) = data;
    4420:	00001437          	lui	s0,0x1
    4424:	80040f93          	addi	t6,s0,-2048 # 800 <CUSTOM2+0x7a5>
        return *((volatile u32*) address);
    4428:	f8014ab7          	lui	s5,0xf8014
        *((volatile u32*) address) = data;
    442c:	f80147b7          	lui	a5,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4430:	00010637          	lui	a2,0x10
    4434:	01f7a023          	sw	t6,0(a5) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    4438:	004a8693          	addi	a3,s5,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    443c:	fff60293          	addi	t0,a2,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    4440:	0006a303          	lw	t1,0(a3)
    4444:	005370b3          	and	ra,t1,t0
        while(spi_cmdAvailability(reg) == 0);
    4448:	fe008ce3          	beqz	ra,4440 <style_multistyle_prepare+0x278>
        *((volatile u32*) address) = data;
    444c:	000015b7          	lui	a1,0x1
    4450:	88058393          	addi	t2,a1,-1920 # 880 <CUSTOM2+0x825>
        return *((volatile u32*) address);
    4454:	f80148b7          	lui	a7,0xf8014
        *((volatile u32*) address) = data;
    4458:	f8014837          	lui	a6,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    445c:	00010e37          	lui	t3,0x10
    4460:	00782023          	sw	t2,0(a6) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    4464:	00488513          	addi	a0,a7,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4468:	fffe0e93          	addi	t4,t3,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    446c:	00052f03          	lw	t5,0(a0)
    4470:	01df7733          	and	a4,t5,t4
        while(spi_cmdAvailability(reg) == 0);
    4474:	fe070ce3          	beqz	a4,446c <style_multistyle_prepare+0x2a4>
    4478:	f8014b37          	lui	s6,0xf8014
        *((volatile u32*) address) = data;
    447c:	f8014c37          	lui	s8,0xf8014
    4480:	1ab00993          	li	s3,427
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4484:	000104b7          	lui	s1,0x10
    4488:	013c2023          	sw	s3,0(s8) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    448c:	004b0a13          	addi	s4,s6,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4490:	fff48413          	addi	s0,s1,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    4494:	000a2f83          	lw	t6,0(s4)
    4498:	008ffab3          	and	s5,t6,s0
        while(spi_cmdAvailability(reg) == 0);
    449c:	fe0a8ce3          	beqz	s5,4494 <style_multistyle_prepare+0x2cc>
        *((volatile u32*) address) = data;
    44a0:	000017b7          	lui	a5,0x1
    44a4:	80078293          	addi	t0,a5,-2048 # 800 <CUSTOM2+0x7a5>
    44a8:	f80146b7          	lui	a3,0xf8014
        return *((volatile u32*) address);
    44ac:	f8b0c637          	lui	a2,0xf8b0c
        *((volatile u32*) address) = data;
    44b0:	0056a023          	sw	t0,0(a3) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    44b4:	ff862303          	lw	t1,-8(a2) # f8b0bff8 <__freertos_irq_stack_top+0xf8b03a78>
    44b8:	ff860093          	addi	ra,a2,-8
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    44bc:	06430593          	addi	a1,t1,100
    44c0:	0000a383          	lw	t2,0(ra) # f8100000 <__freertos_irq_stack_top+0xf80f7a80>
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    44c4:	407588b3          	sub	a7,a1,t2
    44c8:	fe08dce3          	bgez	a7,44c0 <style_multistyle_prepare+0x2f8>
    44cc:	f8014837          	lui	a6,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    44d0:	00010e37          	lui	t3,0x10
    44d4:	00480513          	addi	a0,a6,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    44d8:	fffe0e93          	addi	t4,t3,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    44dc:	10000f13          	li	t5,256
    44e0:	00052703          	lw	a4,0(a0)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    44e4:	01d77b33          	and	s6,a4,t4
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    44e8:	ffeb1ce3          	bne	s6,t5,44e0 <style_multistyle_prepare+0x318>
    44ec:	f8b0cc37          	lui	s8,0xf8b0c
    44f0:	ff8c2983          	lw	s3,-8(s8) # f8b0bff8 <__freertos_irq_stack_top+0xf8b03a78>
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    44f4:	00002a37          	lui	s4,0x2
    44f8:	710a0493          	addi	s1,s4,1808 # 2710 <_malloc_trim_r+0xb4>
    44fc:	ff8c0413          	addi	s0,s8,-8
    4500:	00998fb3          	add	t6,s3,s1
    4504:	00042a83          	lw	s5,0(s0)
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    4508:	415f87b3          	sub	a5,t6,s5
    450c:	fe07dce3          	bgez	a5,4504 <style_multistyle_prepare+0x33c>
    4510:	f8014637          	lui	a2,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4514:	000106b7          	lui	a3,0x10
    4518:	00460293          	addi	t0,a2,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    451c:	fff68313          	addi	t1,a3,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    4520:	0002a083          	lw	ra,0(t0)
    4524:	0060f5b3          	and	a1,ra,t1
        while(spi_cmdAvailability(reg) == 0);
    4528:	fe058ce3          	beqz	a1,4520 <style_multistyle_prepare+0x358>
        *((volatile u32*) address) = data;
    452c:	000013b7          	lui	t2,0x1
    4530:	88038893          	addi	a7,t2,-1920 # 880 <CUSTOM2+0x825>
        return *((volatile u32*) address);
    4534:	f8014837          	lui	a6,0xf8014
        *((volatile u32*) address) = data;
    4538:	f8014537          	lui	a0,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    453c:	00010eb7          	lui	t4,0x10
    4540:	01152023          	sw	a7,0(a0) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    4544:	00480e13          	addi	t3,a6,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4548:	fffe8f13          	addi	t5,t4,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    454c:	000e2703          	lw	a4,0(t3)
    4550:	01e77b33          	and	s6,a4,t5
        while(spi_cmdAvailability(reg) == 0);
    4554:	fe0b0ce3          	beqz	s6,454c <style_multistyle_prepare+0x384>
    4558:	f8014c37          	lui	s8,0xf8014
        *((volatile u32*) address) = data;
    455c:	f80149b7          	lui	s3,0xf8014
    4560:	19f00a13          	li	s4,415
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4564:	00010437          	lui	s0,0x10
    4568:	0149a023          	sw	s4,0(s3) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    456c:	004c0493          	addi	s1,s8,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4570:	fff40f93          	addi	t6,s0,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    4574:	0004aa83          	lw	s5,0(s1)
    4578:	01faf7b3          	and	a5,s5,t6
        while(spi_cmdAvailability(reg) == 0);
    457c:	fe078ce3          	beqz	a5,4574 <style_multistyle_prepare+0x3ac>
    4580:	f8014637          	lui	a2,0xf8014
        *((volatile u32*) address) = data;
    4584:	f80142b7          	lui	t0,0xf8014
    4588:	20000693          	li	a3,512
    458c:	00d2a023          	sw	a3,0(t0) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    4590:	00460313          	addi	t1,a2,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4594:	00032083          	lw	ra,0(t1)
        return read_u32(reg + SPI_BUFFER) >> 16;
    4598:	0100d593          	srli	a1,ra,0x10
        while(spi_rspOccupancy(reg) == 0);
    459c:	fe058ce3          	beqz	a1,4594 <style_multistyle_prepare+0x3cc>
    45a0:	f8b0c3b7          	lui	t2,0xf8b0c
    45a4:	ff838893          	addi	a7,t2,-8 # f8b0bff8 <__freertos_irq_stack_top+0xf8b03a78>
    45a8:	f8014837          	lui	a6,0xf8014
    45ac:	00082503          	lw	a0,0(a6) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
    45b0:	0008ae03          	lw	t3,0(a7)
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    45b4:	00007eb7          	lui	t4,0x7
    45b8:	530e8f13          	addi	t5,t4,1328 # 7530 <__sf+0x118>
        return read_u32(reg + SPI_DATA);
    45bc:	0ff57b13          	zext.b	s6,a0
    45c0:	01ee0733          	add	a4,t3,t5
    45c4:	0008ac03          	lw	s8,0(a7)
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    45c8:	418709b3          	sub	s3,a4,s8
    45cc:	fe09dce3          	bgez	s3,45c4 <style_multistyle_prepare+0x3fc>
    45d0:	f8014a37          	lui	s4,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    45d4:	00010437          	lui	s0,0x10
    45d8:	004a0493          	addi	s1,s4,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    45dc:	fff40f93          	addi	t6,s0,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    45e0:	0004aa83          	lw	s5,0(s1)
    45e4:	01faf7b3          	and	a5,s5,t6
        while(spi_cmdAvailability(reg) == 0);
    45e8:	fe078ce3          	beqz	a5,45e0 <style_multistyle_prepare+0x418>
        *((volatile u32*) address) = data;
    45ec:	00001637          	lui	a2,0x1
    45f0:	80060313          	addi	t1,a2,-2048 # 800 <CUSTOM2+0x7a5>
    45f4:	f80146b7          	lui	a3,0xf8014
        return *((volatile u32*) address);
    45f8:	f8b0c2b7          	lui	t0,0xf8b0c
        *((volatile u32*) address) = data;
    45fc:	0066a023          	sw	t1,0(a3) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    4600:	ff82a083          	lw	ra,-8(t0) # f8b0bff8 <__freertos_irq_stack_top+0xf8b03a78>
    4604:	ff828593          	addi	a1,t0,-8
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    4608:	06408393          	addi	t2,ra,100
    460c:	0005a883          	lw	a7,0(a1)
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    4610:	41138833          	sub	a6,t2,a7
    4614:	fe085ce3          	bgez	a6,460c <style_multistyle_prepare+0x444>
    4618:	f8014537          	lui	a0,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    461c:	00010eb7          	lui	t4,0x10
    4620:	00450e13          	addi	t3,a0,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4624:	fffe8f13          	addi	t5,t4,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    4628:	10000713          	li	a4,256
    462c:	000e2c03          	lw	s8,0(t3)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4630:	01ec79b3          	and	s3,s8,t5
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    4634:	fee99ce3          	bne	s3,a4,462c <style_multistyle_prepare+0x464>
    4638:	f8014a37          	lui	s4,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    463c:	00010437          	lui	s0,0x10
    4640:	004a0493          	addi	s1,s4,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4644:	fff40f93          	addi	t6,s0,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    4648:	0004aa83          	lw	s5,0(s1)
    464c:	01faf7b3          	and	a5,s5,t6
        while(spi_cmdAvailability(reg) == 0);
    4650:	fe078ce3          	beqz	a5,4648 <style_multistyle_prepare+0x480>
        *((volatile u32*) address) = data;
    4654:	00001637          	lui	a2,0x1
    4658:	88060293          	addi	t0,a2,-1920 # 880 <CUSTOM2+0x825>
    465c:	f8014337          	lui	t1,0xf8014
        return *((volatile u32*) address);
    4660:	f80146b7          	lui	a3,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4664:	000103b7          	lui	t2,0x10
        *((volatile u32*) address) = data;
    4668:	00532023          	sw	t0,0(t1) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
    * @param cs 32-bit bitwise chip select setting
    * @param mid 8-bit SPI Flash Manufacturer ID.
*
******************************************************************************/
    static void spiFlash_exit4ByteAddr_(u32 spi, u32 cs, u8 mid){
        switch(mid){
    466c:	09d00093          	li	ra,157
        return *((volatile u32*) address);
    4670:	00468593          	addi	a1,a3,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4674:	fff38893          	addi	a7,t2,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    4678:	181b0263          	beq	s6,ra,47fc <style_multistyle_prepare+0x634>
    467c:	0005ae83          	lw	t4,0(a1)
    4680:	011eff33          	and	t5,t4,a7
        while(spi_cmdAvailability(reg) == 0);
    4684:	fe0f0ce3          	beqz	t5,467c <style_multistyle_prepare+0x4b4>
        *((volatile u32*) address) = data;
    4688:	f8014c37          	lui	s8,0xf8014
    468c:	1e900713          	li	a4,489
    4690:	00ec2023          	sw	a4,0(s8) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    4694:	f80149b7          	lui	s3,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4698:	000104b7          	lui	s1,0x10
    469c:	00498a13          	addi	s4,s3,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    46a0:	fff48413          	addi	s0,s1,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    46a4:	000a2f83          	lw	t6,0(s4)
    46a8:	008ffab3          	and	s5,t6,s0
        while(spi_cmdAvailability(reg) == 0);
    46ac:	fe0a8ce3          	beqz	s5,46a4 <style_multistyle_prepare+0x4dc>
        *((volatile u32*) address) = data;
    46b0:	000017b7          	lui	a5,0x1
    46b4:	80078293          	addi	t0,a5,-2048 # 800 <CUSTOM2+0x7a5>
    46b8:	f8014337          	lui	t1,0xf8014
        return *((volatile u32*) address);
    46bc:	f8b0c637          	lui	a2,0xf8b0c
        *((volatile u32*) address) = data;
    46c0:	00532023          	sw	t0,0(t1) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    46c4:	ff862083          	lw	ra,-8(a2) # f8b0bff8 <__freertos_irq_stack_top+0xf8b03a78>
    46c8:	ff860593          	addi	a1,a2,-8
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    46cc:	06408693          	addi	a3,ra,100
    46d0:	0005a383          	lw	t2,0(a1)
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    46d4:	407688b3          	sub	a7,a3,t2
    46d8:	fe08dce3          	bgez	a7,46d0 <style_multistyle_prepare+0x508>
    46dc:	f8014b37          	lui	s6,0xf8014
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    46e0:	00010537          	lui	a0,0x10
    46e4:	004b0813          	addi	a6,s6,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    46e8:	fff50e13          	addi	t3,a0,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    46ec:	10000e93          	li	t4,256
    46f0:	00082f03          	lw	t5,0(a6)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    46f4:	01cf7c33          	and	s8,t5,t3
    	while(spi_cmdAvailability(reg) != cmdFifo_depth);
    46f8:	ffdc1ce3          	bne	s8,t4,46f0 <style_multistyle_prepare+0x528>
    46fc:	f8014737          	lui	a4,0xf8014
        *((volatile u32*) address) = data;
    4700:	00001a37          	lui	s4,0x1
    4704:	000019b7          	lui	s3,0x1
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4708:	000104b7          	lui	s1,0x10
    470c:	00006b37          	lui	s6,0x6
        return *((volatile u32*) address);
    4710:	f8014c37          	lui	s8,0xf8014
    4714:	00470413          	addi	s0,a4,4 # f8014004 <__freertos_irq_stack_top+0xf800ba84>
    4718:	fff48493          	addi	s1,s1,-1 # ffff <__freertos_irq_stack_top+0x7a7f>
        *((volatile u32*) address) = data;
    471c:	880a0a13          	addi	s4,s4,-1920 # 880 <CUSTOM2+0x825>
    4720:	10b00a93          	li	s5,267
    4724:	80098993          	addi	s3,s3,-2048 # 800 <CUSTOM2+0x7a5>
        spiFlash_f2m(SYSTEM_SPI_0_IO_CTRL, 0, entry->flash_base,
    4728:	00cba603          	lw	a2,12(s7)
                     entry->model_base, entry->model_bytes);
    472c:	008ba683          	lw	a3,8(s7)
    4730:	010baf83          	lw	t6,16(s7)
        return *((volatile u32*) address);
    4734:	00042783          	lw	a5,0(s0)
    4738:	0097f2b3          	and	t0,a5,s1
        while(spi_cmdAvailability(reg) == 0);
    473c:	fe028ce3          	beqz	t0,4734 <style_multistyle_prepare+0x56c>
        *((volatile u32*) address) = data;
    4740:	014c2023          	sw	s4,0(s8) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
        return *((volatile u32*) address);
    4744:	00042303          	lw	t1,0(s0)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4748:	009370b3          	and	ra,t1,s1
        while(spi_cmdAvailability(reg) == 0);
    474c:	fe008ce3          	beqz	ra,4744 <style_multistyle_prepare+0x57c>
        *((volatile u32*) address) = data;
    4750:	015c2023          	sw	s5,0(s8)
    * @param size The size of data to copy
*
******************************************************************************/
    static void spiFlash_f2m_(u32 spi, u32 flashAddress, u32 memoryAddress, u32 size){
        spi_write(spi, 0x0B);
        spi_write(spi, flashAddress >> 16);
    4754:	01065593          	srli	a1,a2,0x10
        return *((volatile u32*) address);
    4758:	00042383          	lw	t2,0(s0)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    475c:	0093f8b3          	and	a7,t2,s1
        while(spi_cmdAvailability(reg) == 0);
    4760:	fe088ce3          	beqz	a7,4758 <style_multistyle_prepare+0x590>
        write_u32(data | SPI_CMD_WRITE, reg + SPI_DATA);
    4764:	0ff5f813          	zext.b	a6,a1
    4768:	10086513          	ori	a0,a6,256
        *((volatile u32*) address) = data;
    476c:	00ac2023          	sw	a0,0(s8)
        spi_write(spi, flashAddress >>  8);
    4770:	00865e13          	srli	t3,a2,0x8
        return *((volatile u32*) address);
    4774:	00042e83          	lw	t4,0(s0)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4778:	009eff33          	and	t5,t4,s1
        while(spi_cmdAvailability(reg) == 0);
    477c:	fe0f0ce3          	beqz	t5,4774 <style_multistyle_prepare+0x5ac>
        write_u32(data | SPI_CMD_WRITE, reg + SPI_DATA);
    4780:	0ffe7713          	zext.b	a4,t3
    4784:	10076793          	ori	a5,a4,256
        *((volatile u32*) address) = data;
    4788:	00fc2023          	sw	a5,0(s8)
        return *((volatile u32*) address);
    478c:	00042283          	lw	t0,0(s0)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4790:	0092f333          	and	t1,t0,s1
        while(spi_cmdAvailability(reg) == 0);
    4794:	fe030ce3          	beqz	t1,478c <style_multistyle_prepare+0x5c4>
        write_u32(data | SPI_CMD_WRITE, reg + SPI_DATA);
    4798:	0ff67093          	zext.b	ra,a2
    479c:	1000e593          	ori	a1,ra,256
        *((volatile u32*) address) = data;
    47a0:	00bc2023          	sw	a1,0(s8)
        return *((volatile u32*) address);
    47a4:	00042383          	lw	t2,0(s0)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    47a8:	0093f8b3          	and	a7,t2,s1
        while(spi_cmdAvailability(reg) == 0);
    47ac:	fe088ce3          	beqz	a7,47a4 <style_multistyle_prepare+0x5dc>
        *((volatile u32*) address) = data;
    47b0:	10000813          	li	a6,256
    47b4:	010c2023          	sw	a6,0(s8)
        spi_write(spi, flashAddress >>  0);
        spi_write(spi, 0);
        uint8_t *ram = (uint8_t *) memoryAddress;
    47b8:	00068593          	mv	a1,a3
        for(u32 idx = 0;idx < size;idx++){
    47bc:	040f8e63          	beqz	t6,4818 <style_multistyle_prepare+0x650>
    47c0:	01f68333          	add	t1,a3,t6
    47c4:	20000093          	li	ra,512
        return *((volatile u32*) address);
    47c8:	00042f83          	lw	t6,0(s0)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    47cc:	009ffe33          	and	t3,t6,s1
        while(spi_cmdAvailability(reg) == 0);
    47d0:	fe0e0ce3          	beqz	t3,47c8 <style_multistyle_prepare+0x600>
        *((volatile u32*) address) = data;
    47d4:	001c2023          	sw	ra,0(s8)
        return *((volatile u32*) address);
    47d8:	00042e83          	lw	t4,0(s0)
        return read_u32(reg + SPI_BUFFER) >> 16;
    47dc:	010edf13          	srli	t5,t4,0x10
        while(spi_rspOccupancy(reg) == 0);
    47e0:	fe0f0ce3          	beqz	t5,47d8 <style_multistyle_prepare+0x610>
    47e4:	000c2283          	lw	t0,0(s8)
            u8 value = spi_read(spi);
            *ram++ = value;
    47e8:	00158793          	addi	a5,a1,1
        return read_u32(reg + SPI_DATA);
    47ec:	00558023          	sb	t0,0(a1)
        for(u32 idx = 0;idx < size;idx++){
    47f0:	02f30463          	beq	t1,a5,4818 <style_multistyle_prepare+0x650>
    47f4:	00078593          	mv	a1,a5
    47f8:	fd1ff06f          	j	47c8 <style_multistyle_prepare+0x600>
    47fc:	0005ab03          	lw	s6,0(a1)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    4800:	011b7833          	and	a6,s6,a7
        while(spi_cmdAvailability(reg) == 0);
    4804:	fe080ce3          	beqz	a6,47fc <style_multistyle_prepare+0x634>
        *((volatile u32*) address) = data;
    4808:	f8014537          	lui	a0,0xf8014
    480c:	12900e13          	li	t3,297
    4810:	01c52023          	sw	t3,0(a0) # f8014000 <__freertos_irq_stack_top+0xf800ba80>
    }
    4814:	e81ff06f          	j	4694 <style_multistyle_prepare+0x4cc>
        return *((volatile u32*) address);
    4818:	00042503          	lw	a0,0(s0)
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    481c:	00957733          	and	a4,a0,s1
        while(spi_cmdAvailability(reg) == 0);
    4820:	fe070ce3          	beqz	a4,4818 <style_multistyle_prepare+0x650>
        *((volatile u32*) address) = data;
    4824:	013c2023          	sw	s3,0(s8)
        bsp_printf("style model %s: flash 0x%x -> DDR 0x%x\r\n",
    4828:	004ba583          	lw	a1,4(s7)
    482c:	2c8b0513          	addi	a0,s6,712 # 62c8 <_data+0x6b0>
    for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
    4830:	018b8b93          	addi	s7,s7,24
        bsp_printf("style model %s: flash 0x%x -> DDR 0x%x\r\n",
    4834:	bc4ff0ef          	jal	3bf8 <bsp_printf>
    for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
    4838:	ef2b98e3          	bne	s7,s2,4728 <style_multistyle_prepare+0x560>
    483c:	01012b03          	lw	s6,16(sp)
    4840:	00812c03          	lw	s8,8(sp)
    4844:	afdff06f          	j	4340 <style_multistyle_prepare+0x178>
    uint32_t h = 0x811C9DC5u;
    4848:	811ca7b7          	lui	a5,0x811ca
    484c:	dc578593          	addi	a1,a5,-571 # 811c9dc5 <__freertos_irq_stack_top+0x811c1845>
    4850:	ae1ff06f          	j	4330 <style_multistyle_prepare+0x168>

00004854 <style_net_status_str>:
    }
}

const char *style_net_status_str(int status)
{
    switch (status) {
    4854:	00750513          	addi	a0,a0,7
    4858:	00700793          	li	a5,7
    485c:	00a7ee63          	bltu	a5,a0,4878 <style_net_status_str+0x24>
    4860:	000062b7          	lui	t0,0x6
    4864:	00251313          	slli	t1,a0,0x2
    4868:	63c28393          	addi	t2,t0,1596 # 663c <CSWTCH.7>
    486c:	006385b3          	add	a1,t2,t1
    4870:	0005a503          	lw	a0,0(a1)
    4874:	00008067          	ret
    4878:	00006637          	lui	a2,0x6
    487c:	33460513          	addi	a0,a2,820 # 6334 <_data+0x71c>
    case STYLE_NET_ERR_ABI:     return "ABI mismatch";
    case STYLE_NET_ERR_RANGE:   return "pass index out of range";
    case STYLE_NET_ERR_BLOB:    return "model blob invalid";
    default:                    return "unknown";
    }
}
    4880:	00008067          	ret

00004884 <style_net_ctx_init>:
void style_net_ctx_init(style_net_ctx_t *ctx,
                        volatile uint32_t *accel,
                        uintptr_t model_base,
                        uintptr_t arena_base)
{
    if (ctx == NULL) {
    4884:	04050463          	beqz	a0,48cc <style_net_ctx_init+0x48>
        return;
    }
    ctx->accel = accel;
    ctx->model_base = model_base;
    ctx->arena_base = arena_base;
    ctx->arena_size = STYLE_NET_ARENA_SIZE;
    4888:	0007e737          	lui	a4,0x7e
    ctx->timeout_cycles = STYLE_NET_DEFAULT_TIMEOUT_CYCLES;
    488c:	0bebc7b7          	lui	a5,0xbebc
    ctx->arena_size = STYLE_NET_ARENA_SIZE;
    4890:	20070293          	addi	t0,a4,512 # 7e200 <__freertos_irq_stack_top+0x75c80>
    ctx->timeout_cycles = STYLE_NET_DEFAULT_TIMEOUT_CYCLES;
    4894:	20078313          	addi	t1,a5,512 # bebc200 <__freertos_irq_stack_top+0xbeb3c80>
    ctx->accel = accel;
    4898:	00b52023          	sw	a1,0(a0)
    ctx->use_irq = 1u;
    489c:	00100393          	li	t2,1
    ctx->last_pass_id = 0u;
    ctx->last_frame_cycles = 0u;
    48a0:	00000593          	li	a1,0
    48a4:	00000813          	li	a6,0
    ctx->model_base = model_base;
    48a8:	00c52223          	sw	a2,4(a0)
    ctx->arena_base = arena_base;
    48ac:	00d52423          	sw	a3,8(a0)
    ctx->arena_size = STYLE_NET_ARENA_SIZE;
    48b0:	00552623          	sw	t0,12(a0)
    ctx->timeout_cycles = STYLE_NET_DEFAULT_TIMEOUT_CYCLES;
    48b4:	00652823          	sw	t1,16(a0)
    ctx->use_irq = 1u;
    48b8:	00752a23          	sw	t2,20(a0)
    ctx->last_pass_id = 0u;
    48bc:	00052c23          	sw	zero,24(a0)
    ctx->last_frame_cycles = 0u;
    48c0:	02b52023          	sw	a1,32(a0)
    48c4:	03052223          	sw	a6,36(a0)
    ctx->output_override = 0u;
    48c8:	02052423          	sw	zero,40(a0)
}
    48cc:	00008067          	ret

000048d0 <style_net_probe>:
int style_net_probe(const style_net_ctx_t *ctx)
{
    uint32_t version;
    uint32_t passes;

    if (ctx == NULL || ctx->accel == NULL) {
    48d0:	06050663          	beqz	a0,493c <style_net_probe+0x6c>
{
    48d4:	ff010113          	addi	sp,sp,-16
    48d8:	00812423          	sw	s0,8(sp)
    48dc:	00050413          	mv	s0,a0
    if (ctx == NULL || ctx->accel == NULL) {
    48e0:	00052503          	lw	a0,0(a0)
{
    48e4:	00112623          	sw	ra,12(sp)
    if (ctx == NULL || ctx->accel == NULL) {
    48e8:	04050663          	beqz	a0,4934 <style_net_probe+0x64>
        return STYLE_NET_ERR_NULL;
    }

    version = style_net_mmio_read(reg_at(ctx->accel, STYLE_NET_REG_VERSION));
    48ec:	08050513          	addi	a0,a0,128
    48f0:	719000ef          	jal	5808 <style_net_mmio_read>
    return base + (off / 4u);
    48f4:	00042783          	lw	a5,0(s0)
    version = style_net_mmio_read(reg_at(ctx->accel, STYLE_NET_REG_VERSION));
    48f8:	00050413          	mv	s0,a0
    passes = style_net_mmio_read(reg_at(ctx->accel, STYLE_NET_REG_PASS_COUNT));
    48fc:	07c78513          	addi	a0,a5,124
    4900:	709000ef          	jal	5808 <style_net_mmio_read>

    if (version != STYLE_NET_ABI_VERSION ||
    4904:	000102b7          	lui	t0,0x10
    4908:	00128313          	addi	t1,t0,1 # 10001 <__freertos_irq_stack_top+0x7a81>
    490c:	02641063          	bne	s0,t1,492c <style_net_probe+0x5c>
    4910:	01300093          	li	ra,19
    4914:	00151c63          	bne	a0,ra,492c <style_net_probe+0x5c>
        passes != style_net_pass_count) {
        return STYLE_NET_ERR_ABI;
    }
    return STYLE_NET_OK;
    4918:	00000513          	li	a0,0
}
    491c:	00c12083          	lw	ra,12(sp)
    4920:	00812403          	lw	s0,8(sp)
    4924:	01010113          	addi	sp,sp,16
    4928:	00008067          	ret
        return STYLE_NET_ERR_ABI;
    492c:	ffb00513          	li	a0,-5
    4930:	fedff06f          	j	491c <style_net_probe+0x4c>
        return STYLE_NET_ERR_NULL;
    4934:	fff00513          	li	a0,-1
    4938:	fe5ff06f          	j	491c <style_net_probe+0x4c>
    493c:	fff00513          	li	a0,-1
}
    4940:	00008067          	ret

00004944 <style_net_load_model>:
    volatile uint32_t *dst;
    const uint32_t *src;
    uint32_t words;
    uint32_t i;

    if (ctx == NULL || ctx->accel == NULL || blob == NULL) {
    4944:	32050263          	beqz	a0,4c68 <style_net_load_model+0x324>
    4948:	00052783          	lw	a5,0(a0)
    494c:	30078e63          	beqz	a5,4c68 <style_net_load_model+0x324>
    4950:	00058313          	mv	t1,a1
    4954:	30058a63          	beqz	a1,4c68 <style_net_load_model+0x324>
    4958:	00060593          	mv	a1,a2
        return STYLE_NET_ERR_NULL;
    }
    if (bytes == 0u || (bytes & 3u) != 0u) {
    495c:	2e060863          	beqz	a2,4c4c <style_net_load_model+0x308>
    4960:	00367293          	andi	t0,a2,3
    4964:	2e029463          	bnez	t0,4c4c <style_net_load_model+0x308>
        return STYLE_NET_ERR_BLOB;
    }

    dst = (volatile uint32_t *)ctx->model_base;
    src = (const uint32_t *)blob;
    words = bytes / 4u;
    4968:	00265813          	srli	a6,a2,0x2
    dst = (volatile uint32_t *)ctx->model_base;
    496c:	00452503          	lw	a0,4(a0)

    for (i = 0; i < words; ++i) {
    4970:	2c080063          	beqz	a6,4c30 <style_net_load_model+0x2ec>
    4974:	00281393          	slli	t2,a6,0x2
    4978:	ffc38893          	addi	a7,t2,-4
    497c:	0028d613          	srli	a2,a7,0x2
    4980:	00160693          	addi	a3,a2,1
    4984:	0076fe13          	andi	t3,a3,7
    4988:	00730833          	add	a6,t1,t2
    498c:	00030713          	mv	a4,t1
    4990:	00030793          	mv	a5,t1
    4994:	406503b3          	sub	t2,a0,t1
    4998:	080e0c63          	beqz	t3,4a30 <style_net_load_model+0xec>
    499c:	00100e93          	li	t4,1
    49a0:	07de0e63          	beq	t3,t4,4a1c <style_net_load_model+0xd8>
    49a4:	00200f13          	li	t5,2
    49a8:	07ee0263          	beq	t3,t5,4a0c <style_net_load_model+0xc8>
    49ac:	00300f93          	li	t6,3
    49b0:	05fe0663          	beq	t3,t6,49fc <style_net_load_model+0xb8>
    49b4:	00400293          	li	t0,4
    49b8:	025e0a63          	beq	t3,t0,49ec <style_net_load_model+0xa8>
    49bc:	00500893          	li	a7,5
    49c0:	011e0e63          	beq	t3,a7,49dc <style_net_load_model+0x98>
    49c4:	00600613          	li	a2,6
    49c8:	28ce1663          	bne	t3,a2,4c54 <style_net_load_model+0x310>
        dst[i] = src[i];
    49cc:	0007ae83          	lw	t4,0(a5)
    49d0:	00778f33          	add	t5,a5,t2
    49d4:	00478793          	addi	a5,a5,4
    49d8:	01df2023          	sw	t4,0(t5)
    49dc:	0007af83          	lw	t6,0(a5)
    49e0:	007782b3          	add	t0,a5,t2
    49e4:	00478793          	addi	a5,a5,4
    49e8:	01f2a023          	sw	t6,0(t0)
    49ec:	0007a883          	lw	a7,0(a5)
    49f0:	00778633          	add	a2,a5,t2
    49f4:	00478793          	addi	a5,a5,4
    49f8:	01162023          	sw	a7,0(a2)
    49fc:	0007a683          	lw	a3,0(a5)
    4a00:	00778e33          	add	t3,a5,t2
    4a04:	00478793          	addi	a5,a5,4
    4a08:	00de2023          	sw	a3,0(t3)
    4a0c:	0007ae83          	lw	t4,0(a5)
    4a10:	00778f33          	add	t5,a5,t2
    4a14:	00478793          	addi	a5,a5,4
    4a18:	01df2023          	sw	t4,0(t5)
    4a1c:	0007af83          	lw	t6,0(a5)
    4a20:	007782b3          	add	t0,a5,t2
    for (i = 0; i < words; ++i) {
    4a24:	00478793          	addi	a5,a5,4
        dst[i] = src[i];
    4a28:	01f2a023          	sw	t6,0(t0)
    for (i = 0; i < words; ++i) {
    4a2c:	09078463          	beq	a5,a6,4ab4 <style_net_load_model+0x170>
        dst[i] = src[i];
    4a30:	0007a683          	lw	a3,0(a5)
    4a34:	007788b3          	add	a7,a5,t2
    for (i = 0; i < words; ++i) {
    4a38:	00478613          	addi	a2,a5,4
        dst[i] = src[i];
    4a3c:	00d8a023          	sw	a3,0(a7)
    4a40:	0047ae03          	lw	t3,4(a5)
    4a44:	00760eb3          	add	t4,a2,t2
    for (i = 0; i < words; ++i) {
    4a48:	00878f13          	addi	t5,a5,8
        dst[i] = src[i];
    4a4c:	01cea023          	sw	t3,0(t4)
    4a50:	0087af83          	lw	t6,8(a5)
    4a54:	007f02b3          	add	t0,t5,t2
    for (i = 0; i < words; ++i) {
    4a58:	00c78693          	addi	a3,a5,12
        dst[i] = src[i];
    4a5c:	01f2a023          	sw	t6,0(t0)
    4a60:	00c7ae03          	lw	t3,12(a5)
    4a64:	00768633          	add	a2,a3,t2
    for (i = 0; i < words; ++i) {
    4a68:	01078893          	addi	a7,a5,16
        dst[i] = src[i];
    4a6c:	01c62023          	sw	t3,0(a2)
    4a70:	0107ae83          	lw	t4,16(a5)
    4a74:	00788f33          	add	t5,a7,t2
    for (i = 0; i < words; ++i) {
    4a78:	01478f93          	addi	t6,a5,20
        dst[i] = src[i];
    4a7c:	01df2023          	sw	t4,0(t5)
    4a80:	0147a283          	lw	t0,20(a5)
    4a84:	007f86b3          	add	a3,t6,t2
    for (i = 0; i < words; ++i) {
    4a88:	01878613          	addi	a2,a5,24
        dst[i] = src[i];
    4a8c:	0056a023          	sw	t0,0(a3)
    4a90:	0187ae03          	lw	t3,24(a5)
    4a94:	007608b3          	add	a7,a2,t2
    for (i = 0; i < words; ++i) {
    4a98:	01c78e93          	addi	t4,a5,28
        dst[i] = src[i];
    4a9c:	01c8a023          	sw	t3,0(a7)
    4aa0:	01c7af03          	lw	t5,28(a5)
    4aa4:	007e8fb3          	add	t6,t4,t2
    for (i = 0; i < words; ++i) {
    4aa8:	02078793          	addi	a5,a5,32
        dst[i] = src[i];
    4aac:	01efa023          	sw	t5,0(t6)
    for (i = 0; i < words; ++i) {
    4ab0:	f90790e3          	bne	a5,a6,4a30 <style_net_load_model+0xec>
    4ab4:	406807b3          	sub	a5,a6,t1
    4ab8:	ffc78293          	addi	t0,a5,-4
    4abc:	0022d693          	srli	a3,t0,0x2
    4ac0:	00168613          	addi	a2,a3,1
    4ac4:	00767e13          	andi	t3,a2,7
    4ac8:	0c0e0263          	beqz	t3,4b8c <style_net_load_model+0x248>
    4acc:	00100893          	li	a7,1
    4ad0:	0b1e0263          	beq	t3,a7,4b74 <style_net_load_model+0x230>
    4ad4:	00200e93          	li	t4,2
    4ad8:	09de0463          	beq	t3,t4,4b60 <style_net_load_model+0x21c>
    4adc:	00300f13          	li	t5,3
    4ae0:	07ee0663          	beq	t3,t5,4b4c <style_net_load_model+0x208>
    4ae4:	00400f93          	li	t6,4
    4ae8:	05fe0863          	beq	t3,t6,4b38 <style_net_load_model+0x1f4>
    4aec:	00500793          	li	a5,5
    4af0:	02fe0a63          	beq	t3,a5,4b24 <style_net_load_model+0x1e0>
    4af4:	00600293          	li	t0,6
    4af8:	005e0c63          	beq	t3,t0,4b10 <style_net_load_model+0x1cc>
    }
    for (i = 0; i < words; ++i) {
        if (dst[i] != src[i]) {
    4afc:	00730733          	add	a4,t1,t2
    4b00:	00072683          	lw	a3,0(a4)
    4b04:	00032603          	lw	a2,0(t1)
    4b08:	14c69263          	bne	a3,a2,4c4c <style_net_load_model+0x308>
    for (i = 0; i < words; ++i) {
    4b0c:	00430713          	addi	a4,t1,4
        if (dst[i] != src[i]) {
    4b10:	00770333          	add	t1,a4,t2
    4b14:	00032e03          	lw	t3,0(t1)
    4b18:	00072883          	lw	a7,0(a4)
    4b1c:	131e1863          	bne	t3,a7,4c4c <style_net_load_model+0x308>
    for (i = 0; i < words; ++i) {
    4b20:	00470713          	addi	a4,a4,4
        if (dst[i] != src[i]) {
    4b24:	00770eb3          	add	t4,a4,t2
    4b28:	000eaf03          	lw	t5,0(t4)
    4b2c:	00072f83          	lw	t6,0(a4)
    4b30:	11ff1e63          	bne	t5,t6,4c4c <style_net_load_model+0x308>
    for (i = 0; i < words; ++i) {
    4b34:	00470713          	addi	a4,a4,4
        if (dst[i] != src[i]) {
    4b38:	007707b3          	add	a5,a4,t2
    4b3c:	0007a283          	lw	t0,0(a5)
    4b40:	00072683          	lw	a3,0(a4)
    4b44:	10d29463          	bne	t0,a3,4c4c <style_net_load_model+0x308>
    for (i = 0; i < words; ++i) {
    4b48:	00470713          	addi	a4,a4,4
        if (dst[i] != src[i]) {
    4b4c:	00770633          	add	a2,a4,t2
    4b50:	00062303          	lw	t1,0(a2)
    4b54:	00072e03          	lw	t3,0(a4)
    4b58:	0fc31a63          	bne	t1,t3,4c4c <style_net_load_model+0x308>
    for (i = 0; i < words; ++i) {
    4b5c:	00470713          	addi	a4,a4,4
        if (dst[i] != src[i]) {
    4b60:	007708b3          	add	a7,a4,t2
    4b64:	0008ae83          	lw	t4,0(a7)
    4b68:	00072f03          	lw	t5,0(a4)
    4b6c:	0fee9063          	bne	t4,t5,4c4c <style_net_load_model+0x308>
    for (i = 0; i < words; ++i) {
    4b70:	00470713          	addi	a4,a4,4
        if (dst[i] != src[i]) {
    4b74:	00770fb3          	add	t6,a4,t2
    4b78:	000fa283          	lw	t0,0(t6)
    4b7c:	00072783          	lw	a5,0(a4)
    4b80:	0cf29663          	bne	t0,a5,4c4c <style_net_load_model+0x308>
    for (i = 0; i < words; ++i) {
    4b84:	00470713          	addi	a4,a4,4
    4b88:	0b070463          	beq	a4,a6,4c30 <style_net_load_model+0x2ec>
    4b8c:	00470693          	addi	a3,a4,4
    4b90:	00870f13          	addi	t5,a4,8
        if (dst[i] != src[i]) {
    4b94:	007702b3          	add	t0,a4,t2
    4b98:	00768fb3          	add	t6,a3,t2
    4b9c:	00072783          	lw	a5,0(a4)
    4ba0:	007f06b3          	add	a3,t5,t2
    4ba4:	0002af03          	lw	t5,0(t0)
    for (i = 0; i < words; ++i) {
    4ba8:	00c70e93          	addi	t4,a4,12
    4bac:	01070e13          	addi	t3,a4,16
    4bb0:	01470313          	addi	t1,a4,20
    4bb4:	01870893          	addi	a7,a4,24
    4bb8:	01c70613          	addi	a2,a4,28
        if (dst[i] != src[i]) {
    4bbc:	007e8eb3          	add	t4,t4,t2
    4bc0:	007e0e33          	add	t3,t3,t2
    4bc4:	00730333          	add	t1,t1,t2
    4bc8:	007888b3          	add	a7,a7,t2
    4bcc:	00760633          	add	a2,a2,t2
    4bd0:	06ff1e63          	bne	t5,a5,4c4c <style_net_load_model+0x308>
    4bd4:	000fa283          	lw	t0,0(t6)
    4bd8:	00472f83          	lw	t6,4(a4)
    4bdc:	07f29863          	bne	t0,t6,4c4c <style_net_load_model+0x308>
    4be0:	0006a683          	lw	a3,0(a3)
    4be4:	00872f03          	lw	t5,8(a4)
    4be8:	07e69263          	bne	a3,t5,4c4c <style_net_load_model+0x308>
    4bec:	000eae83          	lw	t4,0(t4)
    4bf0:	00c72783          	lw	a5,12(a4)
    4bf4:	04fe9c63          	bne	t4,a5,4c4c <style_net_load_model+0x308>
    4bf8:	000e2e03          	lw	t3,0(t3)
    4bfc:	01072283          	lw	t0,16(a4)
    4c00:	045e1663          	bne	t3,t0,4c4c <style_net_load_model+0x308>
    4c04:	00032303          	lw	t1,0(t1)
    4c08:	01472f83          	lw	t6,20(a4)
    4c0c:	05f31063          	bne	t1,t6,4c4c <style_net_load_model+0x308>
    4c10:	0008a883          	lw	a7,0(a7)
    4c14:	01872683          	lw	a3,24(a4)
    4c18:	02d89a63          	bne	a7,a3,4c4c <style_net_load_model+0x308>
    4c1c:	01c72f03          	lw	t5,28(a4)
    4c20:	00062603          	lw	a2,0(a2)
    for (i = 0; i < words; ++i) {
    4c24:	02070713          	addi	a4,a4,32
        if (dst[i] != src[i]) {
    4c28:	03e61263          	bne	a2,t5,4c4c <style_net_load_model+0x308>
    for (i = 0; i < words; ++i) {
    4c2c:	f70710e3          	bne	a4,a6,4b8c <style_net_load_model+0x248>
{
    4c30:	ff010113          	addi	sp,sp,-16
    4c34:	00112623          	sw	ra,12(sp)
            return STYLE_NET_ERR_BLOB;
        }
    }

    /* Publish the blob to the accelerator's DMA view. */
    style_net_cache_flush((const void *)ctx->model_base, bytes);
    4c38:	3e1000ef          	jal	5818 <style_net_cache_flush>
    return STYLE_NET_OK;
}
    4c3c:	00c12083          	lw	ra,12(sp)
    return STYLE_NET_OK;
    4c40:	00000513          	li	a0,0
}
    4c44:	01010113          	addi	sp,sp,16
    4c48:	00008067          	ret
        return STYLE_NET_ERR_BLOB;
    4c4c:	ff900513          	li	a0,-7
    4c50:	00008067          	ret
        dst[i] = src[i];
    4c54:	00032683          	lw	a3,0(t1)
    4c58:	00730e33          	add	t3,t1,t2
    for (i = 0; i < words; ++i) {
    4c5c:	00430793          	addi	a5,t1,4
        dst[i] = src[i];
    4c60:	00de2023          	sw	a3,0(t3)
    for (i = 0; i < words; ++i) {
    4c64:	d69ff06f          	j	49cc <style_net_load_model+0x88>
        return STYLE_NET_ERR_NULL;
    4c68:	fff00513          	li	a0,-1
}
    4c6c:	00008067          	ret

00004c70 <style_net_run_pass>:

int style_net_run_pass(style_net_ctx_t *ctx, uint32_t pass_id)
{
    4c70:	fd010113          	addi	sp,sp,-48
    4c74:	02112623          	sw	ra,44(sp)
    4c78:	02812423          	sw	s0,40(sp)
    volatile uint32_t *a;
    uint32_t status;
    uint32_t irq_seq;
    int rc;

    if (ctx == NULL || ctx->accel == NULL) {
    4c7c:	3a050663          	beqz	a0,5028 <style_net_run_pass+0x3b8>
    4c80:	01412c23          	sw	s4,24(sp)
    4c84:	00052a03          	lw	s4,0(a0)
    4c88:	02912223          	sw	s1,36(sp)
    4c8c:	00050493          	mv	s1,a0
    4c90:	380a0463          	beqz	s4,5018 <style_net_run_pass+0x3a8>
    4c94:	03212023          	sw	s2,32(sp)
        return STYLE_NET_ERR_NULL;
    }
    if (pass_id >= (uint32_t)style_net_pass_count) {
    4c98:	01200793          	li	a5,18
    4c9c:	00058913          	mv	s2,a1
    4ca0:	34b7e863          	bltu	a5,a1,4ff0 <style_net_run_pass+0x380>
        return STYLE_NET_ERR_RANGE;
    }

    a = ctx->accel;
    STYLE_NET_TRACE_P("[A] run_pass=%d\r\n", (int)pass_id);
    status = style_net_mmio_read(reg_at(a, STYLE_NET_REG_STATUS));
    4ca4:	004a0513          	addi	a0,s4,4
    4ca8:	361000ef          	jal	5808 <style_net_mmio_read>
    STYLE_NET_TRACE_P("[B] status=%x\r\n", (unsigned)status);
    if (status & STYLE_NET_STATUS_BUSY) {
    4cac:	00157513          	andi	a0,a0,1
    4cb0:	34051a63          	bnez	a0,5004 <style_net_run_pass+0x394>
    return (ctx->use_irq != 0u) ? STYLE_NET_CTRL_IRQ_EN : 0u;
    4cb4:	0144a703          	lw	a4,20(s1)
        return STYLE_NET_ERR_BUSY;
    }

    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
    4cb8:	000a0513          	mv	a0,s4
    4cbc:	01312e23          	sw	s3,28(sp)
    return (ctx->use_irq != 0u) ? STYLE_NET_CTRL_IRQ_EN : 0u;
    4cc0:	00e030b3          	snez	ra,a4
    4cc4:	00109293          	slli	t0,ra,0x1
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
    4cc8:	0042e593          	ori	a1,t0,4
    4ccc:	01512a23          	sw	s5,20(sp)
    4cd0:	01612823          	sw	s6,16(sp)
    4cd4:	01712623          	sw	s7,12(sp)
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_PASS_ID), pass->pass_id);
    4cd8:	06800413          	li	s0,104
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
    4cdc:	335000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_PASS_ID), pass->pass_id);
    4ce0:	02890333          	mul	t1,s2,s0
    4ce4:	000063b7          	lui	t2,0x6
    4ce8:	65c38a93          	addi	s5,t2,1628 # 665c <style_net_pass_table>
    volatile uint32_t *a = ctx->accel;
    4cec:	0004a983          	lw	s3,0(s1)
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_PASS_ID), pass->pass_id);
    4cf0:	00c98513          	addi	a0,s3,12
    4cf4:	006a8433          	add	s0,s5,t1
    4cf8:	00042b83          	lw	s7,0(s0)
    4cfc:	000b8593          	mv	a1,s7
    4d00:	311000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_STAGE_ID), pass->stage_id);
    4d04:	00442583          	lw	a1,4(s0)
    4d08:	01098513          	addi	a0,s3,16
    4d0c:	305000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_OP), pass->op);
    4d10:	00842583          	lw	a1,8(s0)
    4d14:	01498513          	addi	a0,s3,20
    4d18:	2f9000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_IC), pass->ic);
    4d1c:	00c42583          	lw	a1,12(s0)
    4d20:	01898513          	addi	a0,s3,24
    4d24:	2ed000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_OC), pass->oc);
    4d28:	01042583          	lw	a1,16(s0)
    4d2c:	01c98513          	addi	a0,s3,28
    4d30:	2e1000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_IN_W), pass->in_w);
    4d34:	01442583          	lw	a1,20(s0)
    4d38:	02098513          	addi	a0,s3,32
    4d3c:	2d5000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_IN_H), pass->in_h);
    4d40:	01842583          	lw	a1,24(s0)
    4d44:	02498513          	addi	a0,s3,36
    4d48:	2c9000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_OUT_W), pass->out_w);
    4d4c:	01c42583          	lw	a1,28(s0)
    4d50:	02898513          	addi	a0,s3,40
    4d54:	2bd000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_OUT_H), pass->out_h);
    4d58:	02042583          	lw	a1,32(s0)
    4d5c:	02c98513          	addi	a0,s3,44
    4d60:	2b1000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_STRIDE), pass->stride);
    4d64:	02442583          	lw	a1,36(s0)
    4d68:	03098513          	addi	a0,s3,48
    4d6c:	2a5000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_UPSAMPLE), pass->upsample);
    4d70:	02842583          	lw	a1,40(s0)
    4d74:	03498513          	addi	a0,s3,52
    4d78:	299000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_PAD_MODE), pass->pad_mode);
    4d7c:	02c42583          	lw	a1,44(s0)
    4d80:	03898513          	addi	a0,s3,56
    4d84:	28d000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_WEIGHT_BASE),
    4d88:	03042603          	lw	a2,48(s0)
    4d8c:	0044a583          	lw	a1,4(s1)
    4d90:	03c98513          	addi	a0,s3,60
    4d94:	00c585b3          	add	a1,a1,a2
    4d98:	279000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_W_SCALE_BASE),
    4d9c:	0044a683          	lw	a3,4(s1)
    4da0:	03442803          	lw	a6,52(s0)
    4da4:	04098513          	addi	a0,s3,64
    4da8:	010685b3          	add	a1,a3,a6
    4dac:	265000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_BIAS_BASE),
    4db0:	0044a883          	lw	a7,4(s1)
    4db4:	03842b03          	lw	s6,56(s0)
    4db8:	04498513          	addi	a0,s3,68
    4dbc:	016885b3          	add	a1,a7,s6
    4dc0:	251000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_GAMMA_BASE),
    4dc4:	0044ae03          	lw	t3,4(s1)
    4dc8:	03c42e83          	lw	t4,60(s0)
    4dcc:	04898513          	addi	a0,s3,72
    4dd0:	01de05b3          	add	a1,t3,t4
    4dd4:	23d000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_BETA_BASE),
    4dd8:	0044af03          	lw	t5,4(s1)
    4ddc:	04042f83          	lw	t6,64(s0)
    4de0:	04c98513          	addi	a0,s3,76
    4de4:	01ff05b3          	add	a1,t5,t6
    4de8:	229000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_QUANT_IN_BASE),
    4dec:	0044a703          	lw	a4,4(s1)
    4df0:	04442783          	lw	a5,68(s0)
    4df4:	05098513          	addi	a0,s3,80
    4df8:	00f705b3          	add	a1,a4,a5
    4dfc:	215000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_QUANT_MID_BASE),
    4e00:	0044a283          	lw	t0,4(s1)
    4e04:	04842303          	lw	t1,72(s0)
    4e08:	05498513          	addi	a0,s3,84
    4e0c:	006285b3          	add	a1,t0,t1
    4e10:	201000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_QUANT_OUT_BASE),
    4e14:	0044a383          	lw	t2,4(s1)
    4e18:	04c42583          	lw	a1,76(s0)
    4e1c:	05898513          	addi	a0,s3,88
    4e20:	00b385b3          	add	a1,t2,a1
    4e24:	1ed000ef          	jal	5810 <style_net_mmio_write>
        if (pass->flags & STYLE_NET_FLAG_RAW_CONSUME)
    4e28:	06442b03          	lw	s6,100(s0)
        uint32_t input_base = (uint32_t)(ctx->arena_base + pass->input_base);
    4e2c:	0084a503          	lw	a0,8(s1)
    4e30:	05042603          	lw	a2,80(s0)
        if (pass->flags & STYLE_NET_FLAG_RAW_CONSUME)
    4e34:	200b7813          	andi	a6,s6,512
        uint32_t output_base = (uint32_t)(ctx->arena_base + pass->output_base);
    4e38:	05442683          	lw	a3,84(s0)
            input_base = (uint32_t)STYLE_NET_RAW_SCRATCH_BASE;
    4e3c:	030005b7          	lui	a1,0x3000
        if (pass->flags & STYLE_NET_FLAG_RAW_CONSUME)
    4e40:	12080463          	beqz	a6,4f68 <style_net_run_pass+0x2f8>
        if (pass->flags & STYLE_NET_FLAG_RAW_PRODUCE)
    4e44:	100b7093          	andi	ra,s6,256
            output_base = (uint32_t)STYLE_NET_RAW_SCRATCH_BASE;
    4e48:	03000437          	lui	s0,0x3000
        if (pass->flags & STYLE_NET_FLAG_RAW_PRODUCE)
    4e4c:	10008063          	beqz	ra,4f4c <style_net_run_pass+0x2dc>
        style_net_mmio_write(reg_at(a, STYLE_NET_REG_INPUT_BASE), input_base);
    4e50:	05c98513          	addi	a0,s3,92
    4e54:	1bd000ef          	jal	5810 <style_net_mmio_write>
        if (((uint32_t)pass->pass_id + 1u == (uint32_t)style_net_pass_count) &&
    4e58:	01200893          	li	a7,18
    return base + (off / 4u);
    4e5c:	06098513          	addi	a0,s3,96
        if (((uint32_t)pass->pass_id + 1u == (uint32_t)style_net_pass_count) &&
    4e60:	011b9663          	bne	s7,a7,4e6c <style_net_run_pass+0x1fc>
            (ctx->output_override != 0u)) {
    4e64:	0284a583          	lw	a1,40(s1)
        if (((uint32_t)pass->pass_id + 1u == (uint32_t)style_net_pass_count) &&
    4e68:	00059463          	bnez	a1,4e70 <style_net_run_pass+0x200>
            style_net_mmio_write(reg_at(a, STYLE_NET_REG_OUTPUT_BASE), output_base);
    4e6c:	00040593          	mv	a1,s0
                         (uint32_t)(ctx->arena_base + pass->residual_base));
    4e70:	06800b93          	li	s7,104
    4e74:	03790933          	mul	s2,s2,s7
            style_net_mmio_write(reg_at(a, STYLE_NET_REG_OUTPUT_BASE), output_base);
    4e78:	199000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_RESIDUAL_BASE),
    4e7c:	0084ae03          	lw	t3,8(s1)
    4e80:	06498513          	addi	a0,s3,100
                         (uint32_t)(ctx->arena_base + pass->residual_base));
    4e84:	012a8ab3          	add	s5,s5,s2
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_RESIDUAL_BASE),
    4e88:	058aae83          	lw	t4,88(s5)
    4e8c:	01de05b3          	add	a1,t3,t4
    4e90:	181000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_STATS_BASE),
    4e94:	0084af03          	lw	t5,8(s1)
    4e98:	05caaf83          	lw	t6,92(s5)
    4e9c:	06898513          	addi	a0,s3,104
    4ea0:	01ff05b3          	add	a1,t5,t6
    4ea4:	16d000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_LANES), pass->lanes);
    4ea8:	060aa583          	lw	a1,96(s5)
    4eac:	06c98513          	addi	a0,s3,108
    4eb0:	161000ef          	jal	5810 <style_net_mmio_write>
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_FLAGS), pass->flags);
    4eb4:	000b0593          	mv	a1,s6
    4eb8:	07098513          	addi	a0,s3,112
    4ebc:	155000ef          	jal	5810 <style_net_mmio_write>
                      (unsigned)style_net_mmio_read(
                          reg_at(a, STYLE_NET_REG_PASS_ID)));

    /* The input tensor for this pass lives in DDR; make sure the accelerator
     * sees the producer's writes before START. */
    style_net_cache_flush((const void *)ctx->arena_base, ctx->arena_size);
    4ec0:	00c4a583          	lw	a1,12(s1)
    4ec4:	0084a503          	lw	a0,8(s1)
    4ec8:	151000ef          	jal	5818 <style_net_cache_flush>
    STYLE_NET_TRACE_P("[D] arena flushed\r\n");

    irq_seq = style_net_irq_count();
    4ecc:	181000ef          	jal	584c <style_net_irq_count>
    return (ctx->use_irq != 0u) ? STYLE_NET_CTRL_IRQ_EN : 0u;
    4ed0:	0144a983          	lw	s3,20(s1)
    irq_seq = style_net_irq_count();
    4ed4:	00050b13          	mv	s6,a0
            style_net_idle();
        }
        STYLE_NET_TRACE_P("[D4] starting now\r\n");
    }
#endif
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
    4ed8:	000a0513          	mv	a0,s4
    return (ctx->use_irq != 0u) ? STYLE_NET_CTRL_IRQ_EN : 0u;
    4edc:	01303733          	snez	a4,s3
    4ee0:	00171793          	slli	a5,a4,0x1
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
    4ee4:	0017e593          	ori	a1,a5,1
    4ee8:	129000ef          	jal	5810 <style_net_mmio_write>
    const uint64_t start = style_net_time_now();
    4eec:	135000ef          	jal	5820 <style_net_time_now>
    4ef0:	00050b93          	mv	s7,a0
    4ef4:	00058913          	mv	s2,a1
    return base + (off / 4u);
    4ef8:	0004a283          	lw	t0,0(s1)
            style_net_mmio_read(reg_at(ctx->accel, STYLE_NET_REG_STATUS));
    4efc:	00428513          	addi	a0,t0,4
    4f00:	109000ef          	jal	5808 <style_net_mmio_read>
    4f04:	00050413          	mv	s0,a0
        if (style_net_irq_count() != irq_seq) {
    4f08:	145000ef          	jal	584c <style_net_irq_count>
        if (status & STYLE_NET_STATUS_ERROR) {
    4f0c:	00447313          	andi	t1,s0,4
        if (status & STYLE_NET_STATUS_DONE) {
    4f10:	00247393          	andi	t2,s0,2
        if (style_net_irq_count() != irq_seq) {
    4f14:	06ab1463          	bne	s6,a0,4f7c <style_net_run_pass+0x30c>
        if (status & STYLE_NET_STATUS_ERROR) {
    4f18:	06031863          	bnez	t1,4f88 <style_net_run_pass+0x318>
        if (status & STYLE_NET_STATUS_DONE) {
    4f1c:	0c039263          	bnez	t2,4fe0 <style_net_run_pass+0x370>
        if (ctx->timeout_cycles != 0u &&
    4f20:	0104a583          	lw	a1,16(s1)
    4f24:	02058063          	beqz	a1,4f44 <style_net_run_pass+0x2d4>
            (style_net_time_now() - start) >= ctx->timeout_cycles) {
    4f28:	0f9000ef          	jal	5820 <style_net_time_now>
    4f2c:	41750633          	sub	a2,a0,s7
    4f30:	00c53533          	sltu	a0,a0,a2
    4f34:	41258833          	sub	a6,a1,s2
    4f38:	0104a683          	lw	a3,16(s1)
        if (ctx->timeout_cycles != 0u &&
    4f3c:	0aa81663          	bne	a6,a0,4fe8 <style_net_run_pass+0x378>
    4f40:	0ad67463          	bgeu	a2,a3,4fe8 <style_net_run_pass+0x378>
        style_net_idle();
    4f44:	101000ef          	jal	5844 <style_net_idle>
    for (;;) {
    4f48:	fb1ff06f          	j	4ef8 <style_net_run_pass+0x288>
        uint32_t output_base = (uint32_t)(ctx->arena_base + pass->output_base);
    4f4c:	00d50433          	add	s0,a0,a3
        style_net_mmio_write(reg_at(a, STYLE_NET_REG_INPUT_BASE), input_base);
    4f50:	05c98513          	addi	a0,s3,92
    4f54:	0bd000ef          	jal	5810 <style_net_mmio_write>
        if (((uint32_t)pass->pass_id + 1u == (uint32_t)style_net_pass_count) &&
    4f58:	01200893          	li	a7,18
    return base + (off / 4u);
    4f5c:	06098513          	addi	a0,s3,96
        if (((uint32_t)pass->pass_id + 1u == (uint32_t)style_net_pass_count) &&
    4f60:	f11b82e3          	beq	s7,a7,4e64 <style_net_run_pass+0x1f4>
    4f64:	f09ff06f          	j	4e6c <style_net_run_pass+0x1fc>
        if (pass->flags & STYLE_NET_FLAG_RAW_PRODUCE)
    4f68:	100b7093          	andi	ra,s6,256
        uint32_t input_base = (uint32_t)(ctx->arena_base + pass->input_base);
    4f6c:	00c505b3          	add	a1,a0,a2
            output_base = (uint32_t)STYLE_NET_RAW_SCRATCH_BASE;
    4f70:	03000437          	lui	s0,0x3000
        if (pass->flags & STYLE_NET_FLAG_RAW_PRODUCE)
    4f74:	ec009ee3          	bnez	ra,4e50 <style_net_run_pass+0x1e0>
    4f78:	fd5ff06f          	j	4f4c <style_net_run_pass+0x2dc>
            return (style_net_irq_status() & STYLE_NET_STATUS_ERROR)
    4f7c:	0d9000ef          	jal	5854 <style_net_irq_status>
    4f80:	00457893          	andi	a7,a0,4
                       : STYLE_NET_OK;
    4f84:	04088e63          	beqz	a7,4fe0 <style_net_run_pass+0x370>
    4f88:	ffc00413          	li	s0,-4
                      (int)style_net_irq_count(),
                      (unsigned)style_net_mmio_read(reg_at(a, STYLE_NET_REG_DBG)));

    /* Drop stale lines so a CPU read of the result sees the accelerator's
     * output rather than cached intermediates. */
    style_net_cache_invalidate((const void *)ctx->arena_base, ctx->arena_size);
    4f8c:	00c4a583          	lw	a1,12(s1)
    4f90:	0084a503          	lw	a0,8(s1)
    4f94:	089000ef          	jal	581c <style_net_cache_invalidate>
    return (ctx->use_irq != 0u) ? STYLE_NET_CTRL_IRQ_EN : 0u;
    4f98:	0144a483          	lw	s1,20(s1)

    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
    4f9c:	000a0513          	mv	a0,s4
    return (ctx->use_irq != 0u) ? STYLE_NET_CTRL_IRQ_EN : 0u;
    4fa0:	00903a33          	snez	s4,s1
    4fa4:	001a1e13          	slli	t3,s4,0x1
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
    4fa8:	004e6593          	ori	a1,t3,4
    4fac:	065000ef          	jal	5810 <style_net_mmio_write>
                         STYLE_NET_CTRL_CLEAR | ctrl_irq_bit(ctx));

    return rc;
    4fb0:	02412483          	lw	s1,36(sp)
    4fb4:	02012903          	lw	s2,32(sp)
    4fb8:	01c12983          	lw	s3,28(sp)
    4fbc:	01812a03          	lw	s4,24(sp)
    4fc0:	01412a83          	lw	s5,20(sp)
    4fc4:	01012b03          	lw	s6,16(sp)
    4fc8:	00c12b83          	lw	s7,12(sp)
}
    4fcc:	02c12083          	lw	ra,44(sp)
    4fd0:	00040513          	mv	a0,s0
    4fd4:	02812403          	lw	s0,40(sp)
    4fd8:	03010113          	addi	sp,sp,48
    4fdc:	00008067          	ret
                       : STYLE_NET_OK;
    4fe0:	00000413          	li	s0,0
    4fe4:	fa9ff06f          	j	4f8c <style_net_run_pass+0x31c>
            return STYLE_NET_ERR_TIMEOUT;
    4fe8:	ffd00413          	li	s0,-3
    4fec:	fa1ff06f          	j	4f8c <style_net_run_pass+0x31c>
    4ff0:	02412483          	lw	s1,36(sp)
    4ff4:	02012903          	lw	s2,32(sp)
    4ff8:	01812a03          	lw	s4,24(sp)
        return STYLE_NET_ERR_RANGE;
    4ffc:	ffa00413          	li	s0,-6
    5000:	fcdff06f          	j	4fcc <style_net_run_pass+0x35c>
        return STYLE_NET_ERR_BUSY;
    5004:	02412483          	lw	s1,36(sp)
    5008:	02012903          	lw	s2,32(sp)
    500c:	01812a03          	lw	s4,24(sp)
    5010:	ffe00413          	li	s0,-2
    5014:	fb9ff06f          	j	4fcc <style_net_run_pass+0x35c>
    5018:	02412483          	lw	s1,36(sp)
    501c:	01812a03          	lw	s4,24(sp)
        return STYLE_NET_ERR_NULL;
    5020:	fff00413          	li	s0,-1
    5024:	fa9ff06f          	j	4fcc <style_net_run_pass+0x35c>
    5028:	fff00413          	li	s0,-1
    502c:	fa1ff06f          	j	4fcc <style_net_run_pass+0x35c>

00005030 <style_net_run_passes_from>:

int style_net_run_passes_from(style_net_ctx_t *ctx, uint32_t first, uint32_t count)
{
    5030:	fe010113          	addi	sp,sp,-32
    5034:	00812c23          	sw	s0,24(sp)
    5038:	00050413          	mv	s0,a0
    503c:	00912a23          	sw	s1,20(sp)
    5040:	01412423          	sw	s4,8(sp)
    5044:	00112e23          	sw	ra,28(sp)
    5048:	00058a13          	mv	s4,a1
    504c:	00060493          	mv	s1,a2
    const uint64_t start = style_net_time_now();
    5050:	7d0000ef          	jal	5820 <style_net_time_now>
    uint32_t pass_id;

    if (ctx == NULL || ctx->accel == NULL) {
    5054:	2c040a63          	beqz	s0,5328 <style_net_run_passes_from+0x2f8>
    5058:	00042783          	lw	a5,0(s0) # 3000000 <__freertos_irq_stack_top+0x2ff7a80>
    505c:	2c078663          	beqz	a5,5328 <style_net_run_passes_from+0x2f8>
        return STYLE_NET_ERR_NULL;
    }
    if (first >= (uint32_t)style_net_pass_count) {
    5060:	01200093          	li	ra,18
    5064:	2b40ee63          	bltu	ra,s4,5320 <style_net_run_passes_from+0x2f0>
    5068:	01212823          	sw	s2,16(sp)
    506c:	01312623          	sw	s3,12(sp)
        return STYLE_NET_ERR_RANGE;
    }
    if (first + count > (uint32_t)style_net_pass_count) {
    5070:	009a04b3          	add	s1,s4,s1
    5074:	01300293          	li	t0,19
    5078:	00050913          	mv	s2,a0
    507c:	00058993          	mv	s3,a1
    5080:	2292e463          	bltu	t0,s1,52a8 <style_net_run_passes_from+0x278>
        count = (uint32_t)style_net_pass_count - first;
    }
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5084:	1e9a7063          	bgeu	s4,s1,5264 <style_net_run_passes_from+0x234>
    5088:	41448333          	sub	t1,s1,s4
    508c:	00737393          	andi	t2,t1,7
    5090:	0e038063          	beqz	t2,5170 <style_net_run_passes_from+0x140>
    5094:	00100713          	li	a4,1
    5098:	0ae38c63          	beq	t2,a4,5150 <style_net_run_passes_from+0x120>
    509c:	00200513          	li	a0,2
    50a0:	08a38a63          	beq	t2,a0,5134 <style_net_run_passes_from+0x104>
    50a4:	00300593          	li	a1,3
    50a8:	06b38863          	beq	t2,a1,5118 <style_net_run_passes_from+0xe8>
    50ac:	00400613          	li	a2,4
    50b0:	04c38663          	beq	t2,a2,50fc <style_net_run_passes_from+0xcc>
    50b4:	00500693          	li	a3,5
    50b8:	02d38463          	beq	t2,a3,50e0 <style_net_run_passes_from+0xb0>
    50bc:	00600813          	li	a6,6
    50c0:	21039e63          	bne	t2,a6,52dc <style_net_run_passes_from+0x2ac>
        int rc = style_net_run_pass(ctx, pass_id);
    50c4:	000a0593          	mv	a1,s4
    50c8:	00040513          	mv	a0,s0
    50cc:	ba5ff0ef          	jal	4c70 <style_net_run_pass>

        ctx->last_pass_id = pass_id;
    50d0:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    50d4:	00050893          	mv	a7,a0
        if (rc != STYLE_NET_OK) {
    50d8:	22051263          	bnez	a0,52fc <style_net_run_passes_from+0x2cc>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    50dc:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    50e0:	000a0593          	mv	a1,s4
    50e4:	00040513          	mv	a0,s0
    50e8:	b89ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    50ec:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    50f0:	00050893          	mv	a7,a0
        if (rc != STYLE_NET_OK) {
    50f4:	20051463          	bnez	a0,52fc <style_net_run_passes_from+0x2cc>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    50f8:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    50fc:	000a0593          	mv	a1,s4
    5100:	00040513          	mv	a0,s0
    5104:	b6dff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5108:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    510c:	00050893          	mv	a7,a0
        if (rc != STYLE_NET_OK) {
    5110:	1e051663          	bnez	a0,52fc <style_net_run_passes_from+0x2cc>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5114:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    5118:	000a0593          	mv	a1,s4
    511c:	00040513          	mv	a0,s0
    5120:	b51ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5124:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5128:	00050893          	mv	a7,a0
        if (rc != STYLE_NET_OK) {
    512c:	1c051863          	bnez	a0,52fc <style_net_run_passes_from+0x2cc>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5130:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    5134:	000a0593          	mv	a1,s4
    5138:	00040513          	mv	a0,s0
    513c:	b35ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5140:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5144:	00050893          	mv	a7,a0
        if (rc != STYLE_NET_OK) {
    5148:	1a051a63          	bnez	a0,52fc <style_net_run_passes_from+0x2cc>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    514c:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    5150:	000a0593          	mv	a1,s4
    5154:	00040513          	mv	a0,s0
    5158:	b19ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    515c:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5160:	00050893          	mv	a7,a0
        if (rc != STYLE_NET_OK) {
    5164:	18051c63          	bnez	a0,52fc <style_net_run_passes_from+0x2cc>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5168:	001a0a13          	addi	s4,s4,1
    516c:	0e9a0c63          	beq	s4,s1,5264 <style_net_run_passes_from+0x234>
    5170:	01512223          	sw	s5,4(sp)
    5174:	01612023          	sw	s6,0(sp)
        int rc = style_net_run_pass(ctx, pass_id);
    5178:	000a0593          	mv	a1,s4
    517c:	00040513          	mv	a0,s0
    5180:	af1ff0ef          	jal	4c70 <style_net_run_pass>
    5184:	00050893          	mv	a7,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5188:	001a0a93          	addi	s5,s4,1
        ctx->last_pass_id = pass_id;
    518c:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5190:	000a8593          	mv	a1,s5
    5194:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    5198:	10089c63          	bnez	a7,52b0 <style_net_run_passes_from+0x280>
        int rc = style_net_run_pass(ctx, pass_id);
    519c:	ad5ff0ef          	jal	4c70 <style_net_run_pass>
    51a0:	00050893          	mv	a7,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    51a4:	002a0b13          	addi	s6,s4,2
        ctx->last_pass_id = pass_id;
    51a8:	01542c23          	sw	s5,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    51ac:	000b0593          	mv	a1,s6
    51b0:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    51b4:	0e089e63          	bnez	a7,52b0 <style_net_run_passes_from+0x280>
        int rc = style_net_run_pass(ctx, pass_id);
    51b8:	ab9ff0ef          	jal	4c70 <style_net_run_pass>
    51bc:	00050893          	mv	a7,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    51c0:	003a0a93          	addi	s5,s4,3
        ctx->last_pass_id = pass_id;
    51c4:	01642c23          	sw	s6,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    51c8:	000a8593          	mv	a1,s5
    51cc:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    51d0:	0e089063          	bnez	a7,52b0 <style_net_run_passes_from+0x280>
        int rc = style_net_run_pass(ctx, pass_id);
    51d4:	a9dff0ef          	jal	4c70 <style_net_run_pass>
    51d8:	00050893          	mv	a7,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    51dc:	004a0b13          	addi	s6,s4,4
        ctx->last_pass_id = pass_id;
    51e0:	01542c23          	sw	s5,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    51e4:	000b0593          	mv	a1,s6
    51e8:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    51ec:	0c089263          	bnez	a7,52b0 <style_net_run_passes_from+0x280>
        int rc = style_net_run_pass(ctx, pass_id);
    51f0:	a81ff0ef          	jal	4c70 <style_net_run_pass>
    51f4:	00050893          	mv	a7,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    51f8:	005a0a93          	addi	s5,s4,5
        ctx->last_pass_id = pass_id;
    51fc:	01642c23          	sw	s6,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5200:	000a8593          	mv	a1,s5
    5204:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    5208:	0a089463          	bnez	a7,52b0 <style_net_run_passes_from+0x280>
        int rc = style_net_run_pass(ctx, pass_id);
    520c:	a65ff0ef          	jal	4c70 <style_net_run_pass>
    5210:	00050893          	mv	a7,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5214:	006a0b13          	addi	s6,s4,6
        ctx->last_pass_id = pass_id;
    5218:	01542c23          	sw	s5,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    521c:	000b0593          	mv	a1,s6
    5220:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    5224:	08089663          	bnez	a7,52b0 <style_net_run_passes_from+0x280>
        int rc = style_net_run_pass(ctx, pass_id);
    5228:	a49ff0ef          	jal	4c70 <style_net_run_pass>
    522c:	00050893          	mv	a7,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5230:	007a0a93          	addi	s5,s4,7
        ctx->last_pass_id = pass_id;
    5234:	01642c23          	sw	s6,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5238:	000a8593          	mv	a1,s5
    523c:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    5240:	06089863          	bnez	a7,52b0 <style_net_run_passes_from+0x280>
        int rc = style_net_run_pass(ctx, pass_id);
    5244:	a2dff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5248:	01542c23          	sw	s5,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    524c:	00050893          	mv	a7,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5250:	008a0a13          	addi	s4,s4,8
        if (rc != STYLE_NET_OK) {
    5254:	04051e63          	bnez	a0,52b0 <style_net_run_passes_from+0x280>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5258:	f29a10e3          	bne	s4,s1,5178 <style_net_run_passes_from+0x148>
    525c:	00412a83          	lw	s5,4(sp)
    5260:	00012b03          	lw	s6,0(sp)
            return rc;
        }
    }

    ctx->last_frame_cycles = style_net_time_now() - start;
    5264:	5bc000ef          	jal	5820 <style_net_time_now>
    5268:	41250e33          	sub	t3,a0,s2
    526c:	41358f33          	sub	t5,a1,s3
    5270:	01c53eb3          	sltu	t4,a0,t3
    return STYLE_NET_OK;
    5274:	01012903          	lw	s2,16(sp)
    5278:	00c12983          	lw	s3,12(sp)
    ctx->last_frame_cycles = style_net_time_now() - start;
    527c:	41df0fb3          	sub	t6,t5,t4
    5280:	03c42023          	sw	t3,32(s0)
    5284:	03f42223          	sw	t6,36(s0)
    return STYLE_NET_OK;
    5288:	00000893          	li	a7,0
}
    528c:	01c12083          	lw	ra,28(sp)
    5290:	01812403          	lw	s0,24(sp)
    5294:	01412483          	lw	s1,20(sp)
    5298:	00812a03          	lw	s4,8(sp)
    529c:	00088513          	mv	a0,a7
    52a0:	02010113          	addi	sp,sp,32
    52a4:	00008067          	ret
    if (first + count > (uint32_t)style_net_pass_count) {
    52a8:	01300493          	li	s1,19
    52ac:	dddff06f          	j	5088 <style_net_run_passes_from+0x58>
}
    52b0:	01c12083          	lw	ra,28(sp)
    52b4:	01812403          	lw	s0,24(sp)
    52b8:	01012903          	lw	s2,16(sp)
    52bc:	00c12983          	lw	s3,12(sp)
    52c0:	00412a83          	lw	s5,4(sp)
    52c4:	00012b03          	lw	s6,0(sp)
    52c8:	01412483          	lw	s1,20(sp)
    52cc:	00812a03          	lw	s4,8(sp)
    52d0:	00088513          	mv	a0,a7
    52d4:	02010113          	addi	sp,sp,32
    52d8:	00008067          	ret
        int rc = style_net_run_pass(ctx, pass_id);
    52dc:	000a0593          	mv	a1,s4
    52e0:	00040513          	mv	a0,s0
    52e4:	98dff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    52e8:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    52ec:	00050893          	mv	a7,a0
        if (rc != STYLE_NET_OK) {
    52f0:	00051663          	bnez	a0,52fc <style_net_run_passes_from+0x2cc>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    52f4:	001a0a13          	addi	s4,s4,1
    52f8:	dcdff06f          	j	50c4 <style_net_run_passes_from+0x94>
}
    52fc:	01c12083          	lw	ra,28(sp)
    5300:	01812403          	lw	s0,24(sp)
    5304:	01012903          	lw	s2,16(sp)
    5308:	00c12983          	lw	s3,12(sp)
    530c:	01412483          	lw	s1,20(sp)
    5310:	00812a03          	lw	s4,8(sp)
    5314:	00088513          	mv	a0,a7
    5318:	02010113          	addi	sp,sp,32
    531c:	00008067          	ret
        return STYLE_NET_ERR_RANGE;
    5320:	ffa00893          	li	a7,-6
    5324:	f69ff06f          	j	528c <style_net_run_passes_from+0x25c>
        return STYLE_NET_ERR_NULL;
    5328:	fff00893          	li	a7,-1
    532c:	f61ff06f          	j	528c <style_net_run_passes_from+0x25c>

00005330 <style_net_run_passes>:

int style_net_run_passes(style_net_ctx_t *ctx, uint32_t count)
{
    5330:	fe010113          	addi	sp,sp,-32
    5334:	00812c23          	sw	s0,24(sp)
    5338:	00050413          	mv	s0,a0
    533c:	01412423          	sw	s4,8(sp)
    5340:	00112e23          	sw	ra,28(sp)
    5344:	00058a13          	mv	s4,a1
    const uint64_t start = style_net_time_now();
    5348:	4d8000ef          	jal	5820 <style_net_time_now>
    if (ctx == NULL || ctx->accel == NULL) {
    534c:	2e040663          	beqz	s0,5638 <style_net_run_passes+0x308>
    5350:	00042783          	lw	a5,0(s0)
    5354:	2e078263          	beqz	a5,5638 <style_net_run_passes+0x308>
    5358:	00912a23          	sw	s1,20(sp)
    535c:	01212823          	sw	s2,16(sp)
    5360:	01312623          	sw	s3,12(sp)
    if (first + count > (uint32_t)style_net_pass_count) {
    5364:	01300093          	li	ra,19
    5368:	00050493          	mv	s1,a0
    536c:	00058993          	mv	s3,a1
    5370:	000a0913          	mv	s2,s4
    5374:	2740e063          	bltu	ra,s4,55d4 <style_net_run_passes+0x2a4>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5378:	200a0c63          	beqz	s4,5590 <style_net_run_passes+0x260>
        int rc = style_net_run_pass(ctx, pass_id);
    537c:	00000593          	li	a1,0
    5380:	00040513          	mv	a0,s0
    5384:	01512223          	sw	s5,4(sp)
    5388:	8e9ff0ef          	jal	4c70 <style_net_run_pass>
    538c:	fff90a93          	addi	s5,s2,-1
        ctx->last_pass_id = pass_id;
    5390:	00042c23          	sw	zero,24(s0)
    5394:	007afa93          	andi	s5,s5,7
        int rc = style_net_run_pass(ctx, pass_id);
    5398:	00050613          	mv	a2,a0
        if (rc != STYLE_NET_OK) {
    539c:	26051a63          	bnez	a0,5610 <style_net_run_passes+0x2e0>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    53a0:	00100a13          	li	s4,1
    53a4:	272a7263          	bgeu	s4,s2,5608 <style_net_run_passes+0x2d8>
    53a8:	0e0a8c63          	beqz	s5,54a0 <style_net_run_passes+0x170>
    53ac:	0d4a8a63          	beq	s5,s4,5480 <style_net_run_passes+0x150>
    53b0:	00200293          	li	t0,2
    53b4:	0a5a8863          	beq	s5,t0,5464 <style_net_run_passes+0x134>
    53b8:	00300313          	li	t1,3
    53bc:	086a8663          	beq	s5,t1,5448 <style_net_run_passes+0x118>
    53c0:	00400393          	li	t2,4
    53c4:	067a8463          	beq	s5,t2,542c <style_net_run_passes+0xfc>
    53c8:	00500513          	li	a0,5
    53cc:	04aa8263          	beq	s5,a0,5410 <style_net_run_passes+0xe0>
    53d0:	00600593          	li	a1,6
    53d4:	02ba8063          	beq	s5,a1,53f4 <style_net_run_passes+0xc4>
        int rc = style_net_run_pass(ctx, pass_id);
    53d8:	000a0593          	mv	a1,s4
    53dc:	00040513          	mv	a0,s0
    53e0:	891ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    53e4:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    53e8:	00050613          	mv	a2,a0
        if (rc != STYLE_NET_OK) {
    53ec:	22051263          	bnez	a0,5610 <style_net_run_passes+0x2e0>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    53f0:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    53f4:	000a0593          	mv	a1,s4
    53f8:	00040513          	mv	a0,s0
    53fc:	875ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5400:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5404:	00050613          	mv	a2,a0
        if (rc != STYLE_NET_OK) {
    5408:	20051463          	bnez	a0,5610 <style_net_run_passes+0x2e0>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    540c:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    5410:	000a0593          	mv	a1,s4
    5414:	00040513          	mv	a0,s0
    5418:	859ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    541c:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5420:	00050613          	mv	a2,a0
        if (rc != STYLE_NET_OK) {
    5424:	1e051663          	bnez	a0,5610 <style_net_run_passes+0x2e0>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5428:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    542c:	000a0593          	mv	a1,s4
    5430:	00040513          	mv	a0,s0
    5434:	83dff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5438:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    543c:	00050613          	mv	a2,a0
        if (rc != STYLE_NET_OK) {
    5440:	1c051863          	bnez	a0,5610 <style_net_run_passes+0x2e0>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5444:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    5448:	000a0593          	mv	a1,s4
    544c:	00040513          	mv	a0,s0
    5450:	821ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5454:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5458:	00050613          	mv	a2,a0
        if (rc != STYLE_NET_OK) {
    545c:	1a051a63          	bnez	a0,5610 <style_net_run_passes+0x2e0>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5460:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    5464:	000a0593          	mv	a1,s4
    5468:	00040513          	mv	a0,s0
    546c:	805ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5470:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5474:	00050613          	mv	a2,a0
        if (rc != STYLE_NET_OK) {
    5478:	18051c63          	bnez	a0,5610 <style_net_run_passes+0x2e0>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    547c:	001a0a13          	addi	s4,s4,1
        int rc = style_net_run_pass(ctx, pass_id);
    5480:	000a0593          	mv	a1,s4
    5484:	00040513          	mv	a0,s0
    5488:	fe8ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    548c:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5490:	00050613          	mv	a2,a0
        if (rc != STYLE_NET_OK) {
    5494:	16051e63          	bnez	a0,5610 <style_net_run_passes+0x2e0>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5498:	001a0a13          	addi	s4,s4,1
    549c:	172a7663          	bgeu	s4,s2,5608 <style_net_run_passes+0x2d8>
    54a0:	01612023          	sw	s6,0(sp)
        int rc = style_net_run_pass(ctx, pass_id);
    54a4:	000a0593          	mv	a1,s4
    54a8:	00040513          	mv	a0,s0
    54ac:	fc4ff0ef          	jal	4c70 <style_net_run_pass>
    54b0:	00050613          	mv	a2,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    54b4:	001a0a93          	addi	s5,s4,1
        ctx->last_pass_id = pass_id;
    54b8:	01442c23          	sw	s4,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    54bc:	000a8593          	mv	a1,s5
    54c0:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    54c4:	10061c63          	bnez	a2,55dc <style_net_run_passes+0x2ac>
        int rc = style_net_run_pass(ctx, pass_id);
    54c8:	fa8ff0ef          	jal	4c70 <style_net_run_pass>
    54cc:	00050613          	mv	a2,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    54d0:	002a0b13          	addi	s6,s4,2
        ctx->last_pass_id = pass_id;
    54d4:	01542c23          	sw	s5,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    54d8:	000b0593          	mv	a1,s6
    54dc:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    54e0:	0e061e63          	bnez	a2,55dc <style_net_run_passes+0x2ac>
        int rc = style_net_run_pass(ctx, pass_id);
    54e4:	f8cff0ef          	jal	4c70 <style_net_run_pass>
    54e8:	00050613          	mv	a2,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    54ec:	003a0a93          	addi	s5,s4,3
        ctx->last_pass_id = pass_id;
    54f0:	01642c23          	sw	s6,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    54f4:	000a8593          	mv	a1,s5
    54f8:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    54fc:	0e061063          	bnez	a2,55dc <style_net_run_passes+0x2ac>
        int rc = style_net_run_pass(ctx, pass_id);
    5500:	f70ff0ef          	jal	4c70 <style_net_run_pass>
    5504:	00050613          	mv	a2,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5508:	004a0b13          	addi	s6,s4,4
        ctx->last_pass_id = pass_id;
    550c:	01542c23          	sw	s5,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5510:	000b0593          	mv	a1,s6
    5514:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    5518:	0c061263          	bnez	a2,55dc <style_net_run_passes+0x2ac>
        int rc = style_net_run_pass(ctx, pass_id);
    551c:	f54ff0ef          	jal	4c70 <style_net_run_pass>
    5520:	00050613          	mv	a2,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5524:	005a0a93          	addi	s5,s4,5
        ctx->last_pass_id = pass_id;
    5528:	01642c23          	sw	s6,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    552c:	000a8593          	mv	a1,s5
    5530:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    5534:	0a061463          	bnez	a2,55dc <style_net_run_passes+0x2ac>
        int rc = style_net_run_pass(ctx, pass_id);
    5538:	f38ff0ef          	jal	4c70 <style_net_run_pass>
    553c:	00050613          	mv	a2,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5540:	006a0b13          	addi	s6,s4,6
        ctx->last_pass_id = pass_id;
    5544:	01542c23          	sw	s5,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5548:	000b0593          	mv	a1,s6
    554c:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    5550:	08061663          	bnez	a2,55dc <style_net_run_passes+0x2ac>
        int rc = style_net_run_pass(ctx, pass_id);
    5554:	f1cff0ef          	jal	4c70 <style_net_run_pass>
    5558:	00050613          	mv	a2,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    555c:	007a0a93          	addi	s5,s4,7
        ctx->last_pass_id = pass_id;
    5560:	01642c23          	sw	s6,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5564:	000a8593          	mv	a1,s5
    5568:	00040513          	mv	a0,s0
        if (rc != STYLE_NET_OK) {
    556c:	06061863          	bnez	a2,55dc <style_net_run_passes+0x2ac>
        int rc = style_net_run_pass(ctx, pass_id);
    5570:	f00ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5574:	01542c23          	sw	s5,24(s0)
        int rc = style_net_run_pass(ctx, pass_id);
    5578:	00050613          	mv	a2,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    557c:	008a0a13          	addi	s4,s4,8
        if (rc != STYLE_NET_OK) {
    5580:	04051e63          	bnez	a0,55dc <style_net_run_passes+0x2ac>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5584:	f32a60e3          	bltu	s4,s2,54a4 <style_net_run_passes+0x174>
    5588:	00412a83          	lw	s5,4(sp)
    558c:	00012b03          	lw	s6,0(sp)
    ctx->last_frame_cycles = style_net_time_now() - start;
    5590:	290000ef          	jal	5820 <style_net_time_now>
    5594:	409506b3          	sub	a3,a0,s1
    5598:	41358833          	sub	a6,a1,s3
    559c:	00d53733          	sltu	a4,a0,a3
    return STYLE_NET_OK;
    55a0:	01412483          	lw	s1,20(sp)
    55a4:	01012903          	lw	s2,16(sp)
    55a8:	00c12983          	lw	s3,12(sp)
    ctx->last_frame_cycles = style_net_time_now() - start;
    55ac:	40e808b3          	sub	a7,a6,a4
    55b0:	02d42023          	sw	a3,32(s0)
    55b4:	03142223          	sw	a7,36(s0)
    return STYLE_NET_OK;
    55b8:	00000613          	li	a2,0
     * experiment; see the runtime override in main.c. */
#ifndef STYLE_NET_FIRST_PASS
#define STYLE_NET_FIRST_PASS 0u
#endif
    return style_net_run_passes_from(ctx, (uint32_t)STYLE_NET_FIRST_PASS, count);
}
    55bc:	01c12083          	lw	ra,28(sp)
    55c0:	01812403          	lw	s0,24(sp)
    55c4:	00812a03          	lw	s4,8(sp)
    55c8:	00060513          	mv	a0,a2
    55cc:	02010113          	addi	sp,sp,32
    55d0:	00008067          	ret
    if (first + count > (uint32_t)style_net_pass_count) {
    55d4:	01300913          	li	s2,19
    55d8:	da1ff06f          	j	5378 <style_net_run_passes+0x48>
}
    55dc:	01c12083          	lw	ra,28(sp)
    55e0:	01812403          	lw	s0,24(sp)
    55e4:	01412483          	lw	s1,20(sp)
    55e8:	01012903          	lw	s2,16(sp)
    55ec:	00c12983          	lw	s3,12(sp)
    55f0:	00412a83          	lw	s5,4(sp)
    55f4:	00012b03          	lw	s6,0(sp)
    55f8:	00812a03          	lw	s4,8(sp)
    55fc:	00060513          	mv	a0,a2
    5600:	02010113          	addi	sp,sp,32
    5604:	00008067          	ret
    5608:	00412a83          	lw	s5,4(sp)
    560c:	f85ff06f          	j	5590 <style_net_run_passes+0x260>
    5610:	01c12083          	lw	ra,28(sp)
    5614:	01812403          	lw	s0,24(sp)
    5618:	01412483          	lw	s1,20(sp)
    561c:	01012903          	lw	s2,16(sp)
    5620:	00c12983          	lw	s3,12(sp)
    5624:	00412a83          	lw	s5,4(sp)
    5628:	00812a03          	lw	s4,8(sp)
    562c:	00060513          	mv	a0,a2
    5630:	02010113          	addi	sp,sp,32
    5634:	00008067          	ret
        return STYLE_NET_ERR_NULL;
    5638:	fff00613          	li	a2,-1
    return style_net_run_passes_from(ctx, (uint32_t)STYLE_NET_FIRST_PASS, count);
    563c:	f81ff06f          	j	55bc <style_net_run_passes+0x28c>

00005640 <style_net_run_frame>:

int style_net_run_frame(style_net_ctx_t *ctx)
{
    5640:	fd010113          	addi	sp,sp,-48
    5644:	02912223          	sw	s1,36(sp)
    5648:	00050493          	mv	s1,a0
    564c:	02112623          	sw	ra,44(sp)
    5650:	02812423          	sw	s0,40(sp)
    const uint64_t start = style_net_time_now();
    5654:	1cc000ef          	jal	5820 <style_net_time_now>
    if (ctx == NULL || ctx->accel == NULL) {
    5658:	1a048463          	beqz	s1,5800 <style_net_run_frame+0x1c0>
    565c:	0004a783          	lw	a5,0(s1)
    5660:	1a078063          	beqz	a5,5800 <style_net_run_frame+0x1c0>
    5664:	03212023          	sw	s2,32(sp)
    5668:	01312e23          	sw	s3,28(sp)
    566c:	00050913          	mv	s2,a0
    5670:	00058993          	mv	s3,a1
        int rc = style_net_run_pass(ctx, pass_id);
    5674:	00048513          	mv	a0,s1
    5678:	00000593          	li	a1,0
    567c:	01412c23          	sw	s4,24(sp)
    5680:	df0ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5684:	0004ac23          	sw	zero,24(s1)
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5688:	01300a13          	li	s4,19
        int rc = style_net_run_pass(ctx, pass_id);
    568c:	00050413          	mv	s0,a0
        if (rc != STYLE_NET_OK) {
    5690:	16051063          	bnez	a0,57f0 <style_net_run_frame+0x1b0>
    5694:	01512a23          	sw	s5,20(sp)
    5698:	01612823          	sw	s6,16(sp)
    569c:	01712623          	sw	s7,12(sp)
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    56a0:	00100a93          	li	s5,1
        int rc = style_net_run_pass(ctx, pass_id);
    56a4:	000a8593          	mv	a1,s5
    56a8:	00048513          	mv	a0,s1
    56ac:	dc4ff0ef          	jal	4c70 <style_net_run_pass>
    56b0:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    56b4:	001a8b13          	addi	s6,s5,1
        ctx->last_pass_id = pass_id;
    56b8:	0154ac23          	sw	s5,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    56bc:	000b0593          	mv	a1,s6
    56c0:	00048513          	mv	a0,s1
        if (rc != STYLE_NET_OK) {
    56c4:	0e041e63          	bnez	s0,57c0 <style_net_run_frame+0x180>
        int rc = style_net_run_pass(ctx, pass_id);
    56c8:	da8ff0ef          	jal	4c70 <style_net_run_pass>
    56cc:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    56d0:	002a8b93          	addi	s7,s5,2
        ctx->last_pass_id = pass_id;
    56d4:	0164ac23          	sw	s6,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    56d8:	000b8593          	mv	a1,s7
    56dc:	00048513          	mv	a0,s1
        if (rc != STYLE_NET_OK) {
    56e0:	0e041063          	bnez	s0,57c0 <style_net_run_frame+0x180>
        int rc = style_net_run_pass(ctx, pass_id);
    56e4:	d8cff0ef          	jal	4c70 <style_net_run_pass>
    56e8:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    56ec:	003a8b13          	addi	s6,s5,3
        ctx->last_pass_id = pass_id;
    56f0:	0174ac23          	sw	s7,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    56f4:	000b0593          	mv	a1,s6
    56f8:	00048513          	mv	a0,s1
        if (rc != STYLE_NET_OK) {
    56fc:	0c041263          	bnez	s0,57c0 <style_net_run_frame+0x180>
        int rc = style_net_run_pass(ctx, pass_id);
    5700:	d70ff0ef          	jal	4c70 <style_net_run_pass>
    5704:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5708:	004a8b93          	addi	s7,s5,4
        ctx->last_pass_id = pass_id;
    570c:	0164ac23          	sw	s6,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    5710:	000b8593          	mv	a1,s7
    5714:	00048513          	mv	a0,s1
        if (rc != STYLE_NET_OK) {
    5718:	0a041463          	bnez	s0,57c0 <style_net_run_frame+0x180>
        int rc = style_net_run_pass(ctx, pass_id);
    571c:	d54ff0ef          	jal	4c70 <style_net_run_pass>
    5720:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5724:	005a8b13          	addi	s6,s5,5
        ctx->last_pass_id = pass_id;
    5728:	0174ac23          	sw	s7,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    572c:	000b0593          	mv	a1,s6
    5730:	00048513          	mv	a0,s1
        if (rc != STYLE_NET_OK) {
    5734:	08041663          	bnez	s0,57c0 <style_net_run_frame+0x180>
        int rc = style_net_run_pass(ctx, pass_id);
    5738:	d38ff0ef          	jal	4c70 <style_net_run_pass>
    573c:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5740:	006a8b93          	addi	s7,s5,6
        ctx->last_pass_id = pass_id;
    5744:	0164ac23          	sw	s6,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    5748:	000b8593          	mv	a1,s7
    574c:	00048513          	mv	a0,s1
        if (rc != STYLE_NET_OK) {
    5750:	06041863          	bnez	s0,57c0 <style_net_run_frame+0x180>
        int rc = style_net_run_pass(ctx, pass_id);
    5754:	d1cff0ef          	jal	4c70 <style_net_run_pass>
    5758:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    575c:	007a8b13          	addi	s6,s5,7
        ctx->last_pass_id = pass_id;
    5760:	0174ac23          	sw	s7,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    5764:	000b0593          	mv	a1,s6
    5768:	00048513          	mv	a0,s1
        if (rc != STYLE_NET_OK) {
    576c:	04041a63          	bnez	s0,57c0 <style_net_run_frame+0x180>
        int rc = style_net_run_pass(ctx, pass_id);
    5770:	d00ff0ef          	jal	4c70 <style_net_run_pass>
    5774:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5778:	008a8b93          	addi	s7,s5,8
        ctx->last_pass_id = pass_id;
    577c:	0164ac23          	sw	s6,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    5780:	000b8593          	mv	a1,s7
    5784:	00048513          	mv	a0,s1
        if (rc != STYLE_NET_OK) {
    5788:	02041c63          	bnez	s0,57c0 <style_net_run_frame+0x180>
        int rc = style_net_run_pass(ctx, pass_id);
    578c:	ce4ff0ef          	jal	4c70 <style_net_run_pass>
        ctx->last_pass_id = pass_id;
    5790:	0174ac23          	sw	s7,24(s1)
        int rc = style_net_run_pass(ctx, pass_id);
    5794:	00050413          	mv	s0,a0
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    5798:	009a8a93          	addi	s5,s5,9
        if (rc != STYLE_NET_OK) {
    579c:	02051263          	bnez	a0,57c0 <style_net_run_frame+0x180>
    for (pass_id = first; pass_id < first + count; ++pass_id) {
    57a0:	f14a92e3          	bne	s5,s4,56a4 <style_net_run_frame+0x64>
    ctx->last_frame_cycles = style_net_time_now() - start;
    57a4:	07c000ef          	jal	5820 <style_net_time_now>
    57a8:	412502b3          	sub	t0,a0,s2
    57ac:	00553533          	sltu	a0,a0,t0
    57b0:	41358333          	sub	t1,a1,s3
    57b4:	40a303b3          	sub	t2,t1,a0
    57b8:	0254a023          	sw	t0,32(s1)
    57bc:	0274a223          	sw	t2,36(s1)
    return STYLE_NET_OK;
    57c0:	02012903          	lw	s2,32(sp)
    57c4:	01c12983          	lw	s3,28(sp)
    57c8:	01812a03          	lw	s4,24(sp)
    57cc:	01412a83          	lw	s5,20(sp)
    57d0:	01012b03          	lw	s6,16(sp)
    57d4:	00c12b83          	lw	s7,12(sp)
    return style_net_run_passes(ctx, (uint32_t)style_net_pass_count);
}
    57d8:	02c12083          	lw	ra,44(sp)
    57dc:	00040513          	mv	a0,s0
    57e0:	02812403          	lw	s0,40(sp)
    57e4:	02412483          	lw	s1,36(sp)
    57e8:	03010113          	addi	sp,sp,48
    57ec:	00008067          	ret
    57f0:	02012903          	lw	s2,32(sp)
    57f4:	01c12983          	lw	s3,28(sp)
    57f8:	01812a03          	lw	s4,24(sp)
    57fc:	fddff06f          	j	57d8 <style_net_run_frame+0x198>
        return STYLE_NET_ERR_NULL;
    5800:	fff00413          	li	s0,-1
    return style_net_run_passes(ctx, (uint32_t)style_net_pass_count);
    5804:	fd5ff06f          	j	57d8 <style_net_run_frame+0x198>

00005808 <style_net_mmio_read>:
#include "bsp.h"
#include "vexriscv.h"

uint32_t style_net_mmio_read(const volatile uint32_t *reg)
{
    return *reg;
    5808:	00052503          	lw	a0,0(a0)
}
    580c:	00008067          	ret

00005810 <style_net_mmio_write>:

void style_net_mmio_write(volatile uint32_t *reg, uint32_t value)
{
    *reg = value;
    5810:	00b52023          	sw	a1,0(a0)
}
    5814:	00008067          	ret

00005818 <style_net_cache_flush>:
#else
    /* Write-through cache: invalidate is sufficient and also drops any
     * stale read lines the CPU may still hold. */
    data_cache_invalidate_all();
#endif
}
    5818:	00008067          	ret

0000581c <style_net_cache_invalidate>:

void style_net_cache_invalidate(const void *addr, uint32_t bytes)
    581c:	00008067          	ret

00005820 <style_net_time_now>:
        return *((volatile u32*) address);
    5820:	f8b0c7b7          	lui	a5,0xf8b0c
    5824:	f8b0c6b7          	lui	a3,0xf8b0c
    5828:	ffc78293          	addi	t0,a5,-4 # f8b0bffc <__freertos_irq_stack_top+0xf8b03a7c>
    582c:	ff868313          	addi	t1,a3,-8 # f8b0bff8 <__freertos_irq_stack_top+0xf8b03a78>
    5830:	0002a583          	lw	a1,0(t0)
    5834:	00032503          	lw	a0,0(t1)
    5838:	0002a703          	lw	a4,0(t0)
        } while (clint_getTimeHigh(p) != hi);
    583c:	fee59ae3          	bne	a1,a4,5830 <style_net_time_now+0x10>
}

uint64_t style_net_time_now(void)
{
    return clint_getTime(BSP_CLINT);
}
    5840:	00008067          	ret

00005844 <style_net_idle>:

void style_net_idle(void)
{
    /* Safe on both interrupt and polling paths.  Replace with a WFI
     * once the accelerator IRQ is verified on the board. */
    __asm__ volatile ("nop");
    5844:	00000013          	nop
}
    5848:	00008067          	ret

0000584c <style_net_irq_count>:
    s_irq_count++;
}

uint32_t style_net_irq_count(void)
{
    return s_irq_count;
    584c:	8481a503          	lw	a0,-1976(gp) # 73a8 <s_irq_count>
}
    5850:	00008067          	ret

00005854 <style_net_irq_status>:

uint32_t style_net_irq_status(void)
{
    return s_irq_status;
    5854:	8441a503          	lw	a0,-1980(gp) # 73a4 <s_irq_status>
}
    5858:	00008067          	ret

0000585c <style_net_irq_reset>:

void style_net_irq_reset(void)
{
    s_irq_count = 0u;
    585c:	8401a423          	sw	zero,-1976(gp) # 73a8 <s_irq_count>
    s_irq_status = 0u;
    5860:	8401a223          	sw	zero,-1980(gp) # 73a4 <s_irq_status>
}
    5864:	00008067          	ret

00005868 <style_net_irq_init>:
#ifndef STYLE_NET_HOST_TEST
    /* Install the trap vector FIRST.  On an external interrupt the CPU
     * jumps to mtvec, whose reset value is 0 -- enabling the PLIC
     * before this meant the first interrupt ran off to address 0 and
     * wedged the board. */
    csr_write(mtvec, trap_entry);
    5868:	000062b7          	lui	t0,0x6
    s_accel = accel;
    586c:	84a1a623          	sw	a0,-1972(gp) # 73ac <s_accel>
    csr_write(mtvec, trap_entry);
    5870:	b5428313          	addi	t1,t0,-1196 # 5b54 <trap_entry>
    5874:	30531073          	csrw	mtvec,t1
        *((volatile u32*) address) = data;
    5878:	f8e00737          	lui	a4,0xf8e00
    587c:	00072023          	sw	zero,0(a4) # f8e00000 <__freertos_irq_stack_top+0xf8df7a80>
    5880:	f8c003b7          	lui	t2,0xf8c00
    5884:	00100513          	li	a0,1
    5888:	04a3a023          	sw	a0,64(t2) # f8c00040 <__freertos_irq_stack_top+0xf8bf7ac0>
        return *((volatile u32*) address);
    588c:	f8c026b7          	lui	a3,0xf8c02
    5890:	0006a583          	lw	a1,0(a3) # f8c02000 <__freertos_irq_stack_top+0xf8bf9a80>

    static void plic_set_enable(u32 plic, u32 target,u32 gateway, u32 enable){
        u32 word = plic + PLIC_ENABLE_BASE + target * PLIC_ENABLE_PER_HART + (gateway / 32 * 4);
        u32 mask = 1 << (gateway % 32);
        if (enable)
            write_u32(read_u32(word) | mask, word);
    5894:	00010637          	lui	a2,0x10
    plic_set_priority(BSP_PLIC, STYLE_NET_PLIC_IRQ_ID, 1u);
    plic_set_enable(BSP_PLIC, BSP_PLIC_CPU_0, STYLE_NET_PLIC_IRQ_ID, 1u);

    /* Machine external interrupts.  MPP=M keeps mret returning to
     * machine mode, matching the reference userInterruptDemo. */
    csr_set(mie, MIE_MEIE);
    5898:	00001837          	lui	a6,0x1
    589c:	00c5e8b3          	or	a7,a1,a2
        *((volatile u32*) address) = data;
    58a0:	0116a023          	sw	a7,0(a3)
    58a4:	80080e13          	addi	t3,a6,-2048 # 800 <CUSTOM2+0x7a5>
    58a8:	304e2073          	csrs	mie,t3
    csr_write(mstatus, csr_read(mstatus) | MSTATUS_MPP | MSTATUS_MIE);
    58ac:	30002ef3          	csrr	t4,mstatus
    58b0:	00002f37          	lui	t5,0x2
    58b4:	808f0f93          	addi	t6,t5,-2040 # 1808 <memset+0x24>
    58b8:	01fee7b3          	or	a5,t4,t6
    58bc:	30079073          	csrw	mstatus,a5
#endif
}
    58c0:	00008067          	ret

000058c4 <style_net_irq_handler>:

void style_net_irq_handler(void)
{
    58c4:	fe010113          	addi	sp,sp,-32
    58c8:	00812c23          	sw	s0,24(sp)
        return *((volatile u32*) address);
    58cc:	f8e00437          	lui	s0,0xf8e00
    58d0:	01212823          	sw	s2,16(sp)
    58d4:	00442903          	lw	s2,4(s0) # f8e00004 <__freertos_irq_stack_top+0xf8df7a84>
    58d8:	00112e23          	sw	ra,28(sp)
    uint32_t claim = plic_claim(BSP_PLIC, BSP_PLIC_CPU_0);
    /* Safety valve: a stuck level interrupt must not wedge the CPU.
     * 1024 is far above the one claim a single pass can produce. */
    uint32_t guard = 1024u;

    while (claim != 0u && guard-- != 0u) {
    58dc:	0c090263          	beqz	s2,59a0 <style_net_irq_handler+0xdc>
    58e0:	00912a23          	sw	s1,20(sp)
    58e4:	01312623          	sw	s3,12(sp)
    58e8:	01412423          	sw	s4,8(sp)
    58ec:	01512223          	sw	s5,4(sp)
    58f0:	01612023          	sw	s6,0(sp)
    58f4:	00440413          	addi	s0,s0,4
    58f8:	40000993          	li	s3,1024
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
    58fc:	01000493          	li	s1,16
    5900:	0a990a63          	beq	s2,s1,59b4 <style_net_irq_handler+0xf0>
        *((volatile u32*) address) = data;
    5904:	01242023          	sw	s2,0(s0)
        return *((volatile u32*) address);
    5908:	00042903          	lw	s2,0(s0)
    while (claim != 0u && guard-- != 0u) {
    590c:	08090063          	beqz	s2,598c <style_net_irq_handler+0xc8>
    5910:	fff98993          	addi	s3,s3,-1
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
    5914:	0c990a63          	beq	s2,s1,59e8 <style_net_irq_handler+0x124>
        *((volatile u32*) address) = data;
    5918:	01242023          	sw	s2,0(s0)
        return *((volatile u32*) address);
    591c:	00042903          	lw	s2,0(s0)
    while (claim != 0u && guard-- != 0u) {
    5920:	06090663          	beqz	s2,598c <style_net_irq_handler+0xc8>
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
    5924:	0e990c63          	beq	s2,s1,5a1c <style_net_irq_handler+0x158>
        *((volatile u32*) address) = data;
    5928:	01242023          	sw	s2,0(s0)
        return *((volatile u32*) address);
    592c:	00042903          	lw	s2,0(s0)
    while (claim != 0u && guard-- != 0u) {
    5930:	04090e63          	beqz	s2,598c <style_net_irq_handler+0xc8>
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
    5934:	10990e63          	beq	s2,s1,5a50 <style_net_irq_handler+0x18c>
        *((volatile u32*) address) = data;
    5938:	01242023          	sw	s2,0(s0)
        return *((volatile u32*) address);
    593c:	00042903          	lw	s2,0(s0)
    while (claim != 0u && guard-- != 0u) {
    5940:	04090663          	beqz	s2,598c <style_net_irq_handler+0xc8>
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
    5944:	14990063          	beq	s2,s1,5a84 <style_net_irq_handler+0x1c0>
        *((volatile u32*) address) = data;
    5948:	01242023          	sw	s2,0(s0)
        return *((volatile u32*) address);
    594c:	00042903          	lw	s2,0(s0)
    while (claim != 0u && guard-- != 0u) {
    5950:	02090e63          	beqz	s2,598c <style_net_irq_handler+0xc8>
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
    5954:	16990263          	beq	s2,s1,5ab8 <style_net_irq_handler+0x1f4>
        *((volatile u32*) address) = data;
    5958:	01242023          	sw	s2,0(s0)
        return *((volatile u32*) address);
    595c:	00042903          	lw	s2,0(s0)
    while (claim != 0u && guard-- != 0u) {
    5960:	02090663          	beqz	s2,598c <style_net_irq_handler+0xc8>
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
    5964:	18990463          	beq	s2,s1,5aec <style_net_irq_handler+0x228>
        *((volatile u32*) address) = data;
    5968:	01242023          	sw	s2,0(s0)
        return *((volatile u32*) address);
    596c:	00042903          	lw	s2,0(s0)
    while (claim != 0u && guard-- != 0u) {
    5970:	00090e63          	beqz	s2,598c <style_net_irq_handler+0xc8>
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
    5974:	1a990663          	beq	s2,s1,5b20 <style_net_irq_handler+0x25c>
        *((volatile u32*) address) = data;
    5978:	01242023          	sw	s2,0(s0)
        return *((volatile u32*) address);
    597c:	00042903          	lw	s2,0(s0)
    while (claim != 0u && guard-- != 0u) {
    5980:	00090663          	beqz	s2,598c <style_net_irq_handler+0xc8>
    5984:	ff998993          	addi	s3,s3,-7
    5988:	f6099ce3          	bnez	s3,5900 <style_net_irq_handler+0x3c>
    598c:	01412483          	lw	s1,20(sp)
    5990:	00c12983          	lw	s3,12(sp)
    5994:	00812a03          	lw	s4,8(sp)
    5998:	00412a83          	lw	s5,4(sp)
    599c:	00012b03          	lw	s6,0(sp)
        }
        plic_release(BSP_PLIC, BSP_PLIC_CPU_0, claim);
        claim = plic_claim(BSP_PLIC, BSP_PLIC_CPU_0);
    }
#endif
}
    59a0:	01c12083          	lw	ra,28(sp)
    59a4:	01812403          	lw	s0,24(sp)
    59a8:	01012903          	lw	s2,16(sp)
    59ac:	02010113          	addi	sp,sp,32
    59b0:	00008067          	ret
    if (s_accel == NULL) {
    59b4:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    59b8:	f40506e3          	beqz	a0,5904 <style_net_irq_handler+0x40>
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    59bc:	00450513          	addi	a0,a0,4
    59c0:	e49ff0ef          	jal	5808 <style_net_mmio_read>
    59c4:	00050793          	mv	a5,a0
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    59c8:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    59cc:	00600593          	li	a1,6
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    59d0:	84f1a223          	sw	a5,-1980(gp) # 73a4 <s_irq_status>
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    59d4:	e3dff0ef          	jal	5810 <style_net_mmio_write>
    s_irq_count++;
    59d8:	8481a283          	lw	t0,-1976(gp) # 73a8 <s_irq_count>
    59dc:	00128313          	addi	t1,t0,1
    59e0:	8461a423          	sw	t1,-1976(gp) # 73a8 <s_irq_count>
    59e4:	f21ff06f          	j	5904 <style_net_irq_handler+0x40>
    if (s_accel == NULL) {
    59e8:	84c1a083          	lw	ra,-1972(gp) # 73ac <s_accel>
    59ec:	f20086e3          	beqz	ra,5918 <style_net_irq_handler+0x54>
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    59f0:	00408513          	addi	a0,ra,4
    59f4:	e15ff0ef          	jal	5808 <style_net_mmio_read>
    59f8:	00050393          	mv	t2,a0
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    59fc:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    5a00:	00600593          	li	a1,6
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5a04:	8471a223          	sw	t2,-1980(gp) # 73a4 <s_irq_status>
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5a08:	e09ff0ef          	jal	5810 <style_net_mmio_write>
    s_irq_count++;
    5a0c:	8481a583          	lw	a1,-1976(gp) # 73a8 <s_irq_count>
    5a10:	00158613          	addi	a2,a1,1 # 3000001 <__freertos_irq_stack_top+0x2ff7a81>
    5a14:	84c1a423          	sw	a2,-1976(gp) # 73a8 <s_irq_count>
    5a18:	f01ff06f          	j	5918 <style_net_irq_handler+0x54>
    if (s_accel == NULL) {
    5a1c:	84c1a683          	lw	a3,-1972(gp) # 73ac <s_accel>
    5a20:	f00684e3          	beqz	a3,5928 <style_net_irq_handler+0x64>
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5a24:	00468513          	addi	a0,a3,4
    5a28:	de1ff0ef          	jal	5808 <style_net_mmio_read>
    5a2c:	00050713          	mv	a4,a0
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5a30:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    5a34:	00600593          	li	a1,6
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5a38:	84e1a223          	sw	a4,-1980(gp) # 73a4 <s_irq_status>
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5a3c:	dd5ff0ef          	jal	5810 <style_net_mmio_write>
    s_irq_count++;
    5a40:	8481a803          	lw	a6,-1976(gp) # 73a8 <s_irq_count>
    5a44:	00180893          	addi	a7,a6,1
    5a48:	8511a423          	sw	a7,-1976(gp) # 73a8 <s_irq_count>
    5a4c:	eddff06f          	j	5928 <style_net_irq_handler+0x64>
    if (s_accel == NULL) {
    5a50:	84c1ae03          	lw	t3,-1972(gp) # 73ac <s_accel>
    5a54:	ee0e02e3          	beqz	t3,5938 <style_net_irq_handler+0x74>
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5a58:	004e0513          	addi	a0,t3,4
    5a5c:	dadff0ef          	jal	5808 <style_net_mmio_read>
    5a60:	00050e93          	mv	t4,a0
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5a64:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    5a68:	00600593          	li	a1,6
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5a6c:	85d1a223          	sw	t4,-1980(gp) # 73a4 <s_irq_status>
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5a70:	da1ff0ef          	jal	5810 <style_net_mmio_write>
    s_irq_count++;
    5a74:	8481af03          	lw	t5,-1976(gp) # 73a8 <s_irq_count>
    5a78:	001f0f93          	addi	t6,t5,1
    5a7c:	85f1a423          	sw	t6,-1976(gp) # 73a8 <s_irq_count>
    5a80:	eb9ff06f          	j	5938 <style_net_irq_handler+0x74>
    if (s_accel == NULL) {
    5a84:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    5a88:	ec0500e3          	beqz	a0,5948 <style_net_irq_handler+0x84>
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5a8c:	00450513          	addi	a0,a0,4
    5a90:	d79ff0ef          	jal	5808 <style_net_mmio_read>
    5a94:	00050793          	mv	a5,a0
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5a98:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    5a9c:	00600593          	li	a1,6
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5aa0:	84f1a223          	sw	a5,-1980(gp) # 73a4 <s_irq_status>
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5aa4:	d6dff0ef          	jal	5810 <style_net_mmio_write>
    s_irq_count++;
    5aa8:	8481a283          	lw	t0,-1976(gp) # 73a8 <s_irq_count>
    5aac:	00128313          	addi	t1,t0,1
    5ab0:	8461a423          	sw	t1,-1976(gp) # 73a8 <s_irq_count>
    5ab4:	e95ff06f          	j	5948 <style_net_irq_handler+0x84>
    if (s_accel == NULL) {
    5ab8:	84c1a083          	lw	ra,-1972(gp) # 73ac <s_accel>
    5abc:	e8008ee3          	beqz	ra,5958 <style_net_irq_handler+0x94>
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5ac0:	00408513          	addi	a0,ra,4
    5ac4:	d45ff0ef          	jal	5808 <style_net_mmio_read>
    5ac8:	00050393          	mv	t2,a0
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5acc:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    5ad0:	00600593          	li	a1,6
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5ad4:	8471a223          	sw	t2,-1980(gp) # 73a4 <s_irq_status>
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5ad8:	d39ff0ef          	jal	5810 <style_net_mmio_write>
    s_irq_count++;
    5adc:	8481a583          	lw	a1,-1976(gp) # 73a8 <s_irq_count>
    5ae0:	00158613          	addi	a2,a1,1
    5ae4:	84c1a423          	sw	a2,-1976(gp) # 73a8 <s_irq_count>
    5ae8:	e71ff06f          	j	5958 <style_net_irq_handler+0x94>
    if (s_accel == NULL) {
    5aec:	84c1a683          	lw	a3,-1972(gp) # 73ac <s_accel>
    5af0:	e6068ce3          	beqz	a3,5968 <style_net_irq_handler+0xa4>
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5af4:	00468513          	addi	a0,a3,4
    5af8:	d11ff0ef          	jal	5808 <style_net_mmio_read>
    5afc:	00050713          	mv	a4,a0
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5b00:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    5b04:	00600593          	li	a1,6
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5b08:	84e1a223          	sw	a4,-1980(gp) # 73a4 <s_irq_status>
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5b0c:	d05ff0ef          	jal	5810 <style_net_mmio_write>
    s_irq_count++;
    5b10:	8481a803          	lw	a6,-1976(gp) # 73a8 <s_irq_count>
    5b14:	00180893          	addi	a7,a6,1
    5b18:	8511a423          	sw	a7,-1976(gp) # 73a8 <s_irq_count>
    5b1c:	e4dff06f          	j	5968 <style_net_irq_handler+0xa4>
    if (s_accel == NULL) {
    5b20:	84c1ae03          	lw	t3,-1972(gp) # 73ac <s_accel>
    5b24:	e40e0ae3          	beqz	t3,5978 <style_net_irq_handler+0xb4>
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5b28:	004e0513          	addi	a0,t3,4
    5b2c:	cddff0ef          	jal	5808 <style_net_mmio_read>
    5b30:	00050e93          	mv	t4,a0
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5b34:	84c1a503          	lw	a0,-1972(gp) # 73ac <s_accel>
    5b38:	00600593          	li	a1,6
    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    5b3c:	85d1a223          	sw	t4,-1980(gp) # 73a4 <s_irq_status>
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
    5b40:	cd1ff0ef          	jal	5810 <style_net_mmio_write>
    s_irq_count++;
    5b44:	8481af03          	lw	t5,-1976(gp) # 73a8 <s_irq_count>
    5b48:	001f0f93          	addi	t6,t5,1
    5b4c:	85f1a423          	sw	t6,-1976(gp) # 73a8 <s_irq_count>
    5b50:	e29ff06f          	j	5978 <style_net_irq_handler+0xb4>

00005b54 <trap_entry>:
.global  trap_entry
.align(2) //mtvec require 32 bits allignement
trap_entry:
  addi sp,sp, -16*4
    5b54:	fc010113          	addi	sp,sp,-64
  sw x1,   0*4(sp)
    5b58:	00112023          	sw	ra,0(sp)
  sw x5,   1*4(sp)
    5b5c:	00512223          	sw	t0,4(sp)
  sw x6,   2*4(sp)
    5b60:	00612423          	sw	t1,8(sp)
  sw x7,   3*4(sp)
    5b64:	00712623          	sw	t2,12(sp)
  sw x10,  4*4(sp)
    5b68:	00a12823          	sw	a0,16(sp)
  sw x11,  5*4(sp)
    5b6c:	00b12a23          	sw	a1,20(sp)
  sw x12,  6*4(sp)
    5b70:	00c12c23          	sw	a2,24(sp)
  sw x13,  7*4(sp)
    5b74:	00d12e23          	sw	a3,28(sp)
  sw x14,  8*4(sp)
    5b78:	02e12023          	sw	a4,32(sp)
  sw x15,  9*4(sp)
    5b7c:	02f12223          	sw	a5,36(sp)
  sw x16, 10*4(sp)
    5b80:	03012423          	sw	a6,40(sp)
  sw x17, 11*4(sp)
    5b84:	03112623          	sw	a7,44(sp)
  sw x28, 12*4(sp)
    5b88:	03c12823          	sw	t3,48(sp)
  sw x29, 13*4(sp)
    5b8c:	03d12a23          	sw	t4,52(sp)
  sw x30, 14*4(sp)
    5b90:	03e12c23          	sw	t5,56(sp)
  sw x31, 15*4(sp)
    5b94:	03f12e23          	sw	t6,60(sp)
  call trap
    5b98:	fd1fd0ef          	jal	3b68 <trap>
  lw x1 ,  0*4(sp)
    5b9c:	00012083          	lw	ra,0(sp)
  lw x5,   1*4(sp)
    5ba0:	00412283          	lw	t0,4(sp)
  lw x6,   2*4(sp)
    5ba4:	00812303          	lw	t1,8(sp)
  lw x7,   3*4(sp)
    5ba8:	00c12383          	lw	t2,12(sp)
  lw x10,  4*4(sp)
    5bac:	01012503          	lw	a0,16(sp)
  lw x11,  5*4(sp)
    5bb0:	01412583          	lw	a1,20(sp)
  lw x12,  6*4(sp)
    5bb4:	01812603          	lw	a2,24(sp)
  lw x13,  7*4(sp)
    5bb8:	01c12683          	lw	a3,28(sp)
  lw x14,  8*4(sp)
    5bbc:	02012703          	lw	a4,32(sp)
  lw x15,  9*4(sp)
    5bc0:	02412783          	lw	a5,36(sp)
  lw x16, 10*4(sp)
    5bc4:	02812803          	lw	a6,40(sp)
  lw x17, 11*4(sp)
    5bc8:	02c12883          	lw	a7,44(sp)
  lw x28, 12*4(sp)
    5bcc:	03012e03          	lw	t3,48(sp)
  lw x29, 13*4(sp)
    5bd0:	03412e83          	lw	t4,52(sp)
  lw x30, 14*4(sp)
    5bd4:	03812f03          	lw	t5,56(sp)
  lw x31, 15*4(sp)
    5bd8:	03c12f83          	lw	t6,60(sp)
  addi sp,sp, 16*4
    5bdc:	04010113          	addi	sp,sp,64
  mret
    5be0:	30200073          	mret

00005be4 <_sbrk>:
    5be4:	88418713          	addi	a4,gp,-1916 # 73e4 <heap_end.0>
    5be8:	00072783          	lw	a5,0(a4)
    5bec:	00078a63          	beqz	a5,5c00 <_sbrk+0x1c>
    5bf0:	00a78533          	add	a0,a5,a0
    5bf4:	00a72023          	sw	a0,0(a4)
    5bf8:	00078513          	mv	a0,a5
    5bfc:	00008067          	ret
    5c00:	00002797          	auipc	a5,0x2
    5c04:	97878793          	addi	a5,a5,-1672 # 7578 <_end>
    5c08:	00a78533          	add	a0,a5,a0
    5c0c:	00a72023          	sw	a0,0(a4)
    5c10:	00078513          	mv	a0,a5
    5c14:	00008067          	ret
