CL_X64_PATH	:= "C:\mingw64\bin\"
CL_X86_PATH	:= "C:\mingw32\bin\"
LD_X64_PATH	:= "C:\mingw64\x86_64-w64-mingw32\bin\"
LD_X86_PATH	:= "C:\mingw32\i686-w64-mingw32\bin\"


CC_x64  	:= $(CL_X64_PATH)gcc
CC_x86		:= $(CL_X86_PATH)gcc
LD_x64  	:= $(LD_X64_PATH)ld
LD_x86		:= $(LD_X86_PATH)ld
RC_x64  	:= x86_64-w64-mingw32-windres
NASM_x64	:= nasm -f win64
NASM_x86	:= nasm -f win32

NAME 		:= HiddenDesktop
UI  		:= HVNC\ Server

CLIENT 		:= client
SERVER 		:= server
APP_SRC 	:= $(wildcard ./$(CLIENT)/launchers/*.c)
LAUNCHERS	:= $(APP_SRC:%.c=%.o)
OUT 		:= bin

SCFLAGS  	:= $(SCFLAGS) -Os -fno-asynchronous-unwind-tables -nostdlib 
SCFLAGS  	:= $(SCFLAGS) -fno-ident -fpack-struct=8 -falign-functions=1 
SCFLAGS 	:= $(SCFLAGS) -s -ffunction-sections -falign-jumps=1 
SCFLAGS  	:= $(SCFLAGS) -falign-labels=1 -fPIC -fno-exceptions -Wall  
SCFLAGS  	:= $(SCFLAGS) -Wl,-s,--no-seh,--enable-stdcall-fixup,-T$(CLIENT)/LinkOrder.ld

BFFLAGS 	:= $(BFFLAGS) -Os -s -Qn -nostdlib -Wall
BFFLAGS 	:= $(BFFLAGS) -Wl,-s,--exclude-all-symbols,--no-leading-underscore 
 

.PHONY: default release client server launchers clean zip

default: clean client server
release: default zip
client: x64 x86

x86 x64:

	@ $(NASM_$@) $(CLIENT)/asm/$@/start.asm -o $(OUT)/SCStart.$@.o
	@ $(CC_$@) $(OUT)/SCStart.$@.o $(CLIENT)/*.c -o $(OUT)/$(NAME).$@.exe $(SCFLAGS) -I$(CLIENT)
	@ python3 scripts/extract.py -f $(OUT)/$(NAME).$@.exe -o $(OUT)/$(NAME).$@.bin

	@ $(NASM_$@) $(CLIENT)/bof/start.asm -o $(OUT)/BOFStart.$@.o
	@ $(CC_$@) $(CLIENT)/bof/main.c -c -o $(OUT)/BOF.$@.o $(BFFLAGS)
	@ $(LD_$@) -r $(OUT)/BOF.$@.o $(OUT)/BOFStart.$@.o -o $(OUT)/$(NAME).$@.o --enable-stdcall-fixup

	@ $(MAKE) ARCH=$@ -s launchers
	
	@ del $(OUT)\SCStart.$@.o 
	@ del $(OUT)\BOF.$@.o 
	@ del $(OUT)\BOFStart.$@.o 
	@ del $(OUT)\$(NAME).$@.bin 
	@ del $(OUT)\$(NAME).$@.exe

launchers: $(LAUNCHERS)

server:
	# HVNC Server and UI
	@ $(RC_x64) $(SERVER)/resource.rc -O coff -o $(OUT)/resources.x64.o
	@ $(CC_x64) $(SERVER)/*.c $(OUT)/resources.x64.o -o $(OUT)/$(UI).exe -static -Wall -Werror -lws2_32 -luser32 -lgdi32 -I$(SERVER)
	@ rm $(OUT)/resources.x64.o 2>/dev/null || true

.c.o:
	@ $(CC_$(ARCH)) -o $(OUT)/$(basename $(notdir $@)).$(ARCH).o -c $< $(BFFLAGS)

clean:
	@ rm $(OUT)/*.o 2>/dev/null || true
	@ rm $(OUT)/*.exe 2>/dev/null || true
	@ rm $(OUT)/*.bin 2>/dev/null || true
	@ rm $(OUT)/$(NAME).zip 2>/dev/null || true

zip:
	# Release Zip
	@ zip -j $(OUT)/$(NAME).zip $(OUT)/*.x86.o $(OUT)/*.x64.o $(OUT)/$(UI).exe $(OUT)/$(NAME).cna 1>/dev/null
