unit MD5;

{**************************************************************************

   MD5 from rfc1231.txt

   Copyright (C) 2002 Go Maeda <g_maeda@mars.dti.ne.jp>
   This work is derived from the RSA Data Security, Inc. MD5 Message-Digest
   Algorithm.

   Convert for Delphi by Ayakawa,Marinosuke

   2000/11/17 1st. convert to delphi
   2004/07/04 2nd. change param string to pbyte
   2006/09/03 3rd. use $Q-/$Q+ for D7

   このユニットはご自由に使用してください。
   配布・転載もご自由にどうぞ。
   なお、使用する場合はご自身の責任にてどうぞ。作者は一切責任を持ちません。

 **************************************************************************}

interface

uses
  windows,sysutils,classes;

type
  TMD5BreakFunc = function:boolean of Object;

function CalcMD5(ASrc:PByte; ASize:integer):string;
function CalcFileMD5(AFilename:string):string;

function CalcFileMD5_Sp(AFilename:string; ABreak:TMD5BreakFunc):string;

implementation

type
  UINT2 = WORD;
  UINT4 = DWORD;

  TARYUINT4 = array[0..3] of UINT4;
  TARYBYTE64 = array[0..63] of byte;

  TMD5_CTX = packed record
    state : TARYUINT4;
    count : array[0..1] of UINT4;
    buffer : TARYBYTE64;
  end;

const
  S11=7;
  S12=12;
  S13=17;
  S14=22;
  S21=5;
  S22=9;
  S23=14;
  S24=20;
  S31=4;
  S32=11;
  S33=16;
  S34=23;
  S41=6;
  S42=10;
  S43=15;
  S44=21;

  PADDING = #$80#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0+
            #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0+
            #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0+
            #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0;

{$Q-}

// F, G, H and I are basic MD5 functions.
function F(x,y,z:UINT4):UINT4;
begin
  result:= (x AND y) OR ((NOT x) AND z);
end;

function G(x,y,z:UINT4):UINT4;
begin
  result:= (x AND z) OR (y AND (NOT z));
end;

function H(x,y,z:UINT4):UINT4;
begin
  result:=x XOR y XOR z;
end;

function I(x,y,z:UINT4):UINT4;
begin
  result:=y XOR (x OR (NOT z));
end;

// ROTATE_LEFT rotates x left n bits.
function ROTATE_LEFT(x,n:DWORD):DWORD;
begin
  result:= (x SHL n) OR (x SHR (32-n));
end;

// FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4.
// Rotation is separate from addition to prevent recomputation.
procedure FF(var a:DWORD; b,c,d,x,s,ac:DWORD);
begin
  a:=a+F(b,c,d)+x+ac;
  a:=ROTATE_LEFT(a,s);
  a:=a+b;
end;

procedure GG(var a:DWORD; b,c,d,x,s,ac:DWORD);
begin
  a:=a+G(b,c,d)+x+ac;
  a:=ROTATE_LEFT(a,s);
  a:=a+b;
end;

procedure HH(var a:DWORD; b,c,d,x,s,ac:DWORD);
begin
  a:=a+H(b,c,d)+x+ac;
  a:=ROTATE_LEFT(a,s);
  a:=a+b;
end;

procedure II(var a:DWORD; b,c,d,x,s,ac:DWORD);
begin
  a:=a+I(b,c,d)+x+ac;
  a:=ROTATE_LEFT(a,s);
  a:=a+b;
end;

// for (i=0; i<cpylen; i++) context->buffer[bufidx+i]=src[srcidx+i]
procedure MD5_memcpy(var context:TMD5_CTX; bufidx:integer; src:PByte; srcidx:integer; cpylen:integer);
var
  i : integer;
  p : PByte;
begin
  // srcidx 0-origin. but string is 1-origin => 1+srcidx+i
  //FOR i:=0 TO cpylen-1 DO context.buffer[bufidx+i]:=BYTE(ord(src[1+srcidx+i]));
  p:=src;
  Inc(p,srcidx);
  FOR i:=0 TO cpylen-1 DO BEGIN
    context.buffer[bufidx+i]:=p^; Inc(p);
  END;
end;

// MD5 basic transformation. Transforms state based on block.
procedure MD5Transform(var state:TARYUINT4; block:TARYBYTE64);
var
  a,b,c,d : UINT4;
  x : array[0..15] of UINT4;
  procedure Decode;
  var
    i,j : integer;
  begin
    i:=0; j:=0;
    WHILE j<64 DO BEGIN
      x[i]:=block[j] OR (block[j+1] SHL 8) OR (block[j+2] SHL 16) OR (block[j+3] SHL 24);
      INC(i); INC(j,4);
    END;
  end;
begin
  a:=state[0]; b:=state[1]; c:=state[2]; d:=state[3];

  Decode;

  //* Round 1 */
  FF (a, b, c, d, x[ 0], S11, $d76aa478); //* 1 */
  FF (d, a, b, c, x[ 1], S12, $e8c7b756); //* 2 */
  FF (c, d, a, b, x[ 2], S13, $242070db); //* 3 */
  FF (b, c, d, a, x[ 3], S14, $c1bdceee); //* 4 */
  FF (a, b, c, d, x[ 4], S11, $f57c0faf); //* 5 */
  FF (d, a, b, c, x[ 5], S12, $4787c62a); //* 6 */
  FF (c, d, a, b, x[ 6], S13, $a8304613); //* 7 */
  FF (b, c, d, a, x[ 7], S14, $fd469501); //* 8 */
  FF (a, b, c, d, x[ 8], S11, $698098d8); //* 9 */
  FF (d, a, b, c, x[ 9], S12, $8b44f7af); //* 10 */
  FF (c, d, a, b, x[10], S13, $ffff5bb1); //* 11 */
  FF (b, c, d, a, x[11], S14, $895cd7be); //* 12 */
  FF (a, b, c, d, x[12], S11, $6b901122); //* 13 */
  FF (d, a, b, c, x[13], S12, $fd987193); //* 14 */
  FF (c, d, a, b, x[14], S13, $a679438e); //* 15 */
  FF (b, c, d, a, x[15], S14, $49b40821); //* 16 */

 //* Round 2 */
  GG (a, b, c, d, x[ 1], S21, $f61e2562); //* 17 */
  GG (d, a, b, c, x[ 6], S22, $c040b340); //* 18 */
  GG (c, d, a, b, x[11], S23, $265e5a51); //* 19 */
  GG (b, c, d, a, x[ 0], S24, $e9b6c7aa); //* 20 */
  GG (a, b, c, d, x[ 5], S21, $d62f105d); //* 21 */
  GG (d, a, b, c, x[10], S22,  $2441453); //* 22 */
  GG (c, d, a, b, x[15], S23, $d8a1e681); //* 23 */
  GG (b, c, d, a, x[ 4], S24, $e7d3fbc8); //* 24 */
  GG (a, b, c, d, x[ 9], S21, $21e1cde6); //* 25 */
  GG (d, a, b, c, x[14], S22, $c33707d6); //* 26 */
  GG (c, d, a, b, x[ 3], S23, $f4d50d87); //* 27 */
  GG (b, c, d, a, x[ 8], S24, $455a14ed); //* 28 */
  GG (a, b, c, d, x[13], S21, $a9e3e905); //* 29 */
  GG (d, a, b, c, x[ 2], S22, $fcefa3f8); //* 30 */
  GG (c, d, a, b, x[ 7], S23, $676f02d9); //* 31 */
  GG (b, c, d, a, x[12], S24, $8d2a4c8a); //* 32 */

  //* Round 3 */
  HH (a, b, c, d, x[ 5], S31, $fffa3942); //* 33 */
  HH (d, a, b, c, x[ 8], S32, $8771f681); //* 34 */
  HH (c, d, a, b, x[11], S33, $6d9d6122); //* 35 */
  HH (b, c, d, a, x[14], S34, $fde5380c); //* 36 */
  HH (a, b, c, d, x[ 1], S31, $a4beea44); //* 37 */
  HH (d, a, b, c, x[ 4], S32, $4bdecfa9); //* 38 */
  HH (c, d, a, b, x[ 7], S33, $f6bb4b60); //* 39 */
  HH (b, c, d, a, x[10], S34, $bebfbc70); //* 40 */
  HH (a, b, c, d, x[13], S31, $289b7ec6); //* 41 */
  HH (d, a, b, c, x[ 0], S32, $eaa127fa); //* 42 */
  HH (c, d, a, b, x[ 3], S33, $d4ef3085); //* 43 */
  HH (b, c, d, a, x[ 6], S34,  $4881d05); //* 44 */
  HH (a, b, c, d, x[ 9], S31, $d9d4d039); //* 45 */
  HH (d, a, b, c, x[12], S32, $e6db99e5); //* 46 */
  HH (c, d, a, b, x[15], S33, $1fa27cf8); //* 47 */
  HH (b, c, d, a, x[ 2], S34, $c4ac5665); //* 48 */

  //* Round 4 */
  II (a, b, c, d, x[ 0], S41, $f4292244); //* 49 */
  II (d, a, b, c, x[ 7], S42, $432aff97); //* 50 */
  II (c, d, a, b, x[14], S43, $ab9423a7); //* 51 */
  II (b, c, d, a, x[ 5], S44, $fc93a039); //* 52 */
  II (a, b, c, d, x[12], S41, $655b59c3); //* 53 */
  II (d, a, b, c, x[ 3], S42, $8f0ccc92); //* 54 */
  II (c, d, a, b, x[10], S43, $ffeff47d); //* 55 */
  II (b, c, d, a, x[ 1], S44, $85845dd1); //* 56 */
  II (a, b, c, d, x[ 8], S41, $6fa87e4f); //* 57 */
  II (d, a, b, c, x[15], S42, $fe2ce6e0); //* 58 */
  II (c, d, a, b, x[ 6], S43, $a3014314); //* 59 */
  II (b, c, d, a, x[13], S44, $4e0811a1); //* 60 */
  II (a, b, c, d, x[ 4], S41, $f7537e82); //* 61 */
  II (d, a, b, c, x[11], S42, $bd3af235); //* 62 */
  II (c, d, a, b, x[ 2], S43, $2ad7d2bb); //* 63 */
  II (b, c, d, a, x[ 9], S44, $eb86d391); //* 64 */

  INC(state[0],a);
  INC(state[1],b);
  INC(state[2],c);
  INC(state[3],d);

  // Zeroize sensitive information.
  FillChar(x[0],sizeof(x),0); // MD5_memset
end;

///////////////////////////////////////////////////////////////////////////
//
// MD5 initialization. Begins an MD5 operation, writing a new context.
//
///////////////////////////////////////////////////////////////////////////
procedure MD5Init(var md5ctx:TMD5_CTX);
begin
  WITH md5ctx DO BEGIN
    count[0]:=0;
    count[1]:=0;
    // Load magic initialization constants.
    state[0]:=$67452301;
    state[1]:=$efcdab89;
    state[2]:=$98badcfe;
    state[3]:=$10325476;
  END;
end;

procedure MD5Update(var context:TMD5_CTX; inputdata:PByte; inputlen:DWORD);
var
  i,index,partLen : DWORD;
  work : TARYBYTE64;
  pB : PByte;
begin
  // Compute number of bytes mod 64
  index := (context.count[0] SHR 3) AND $3F;

  // Update number of bits
  INC(context.count[0],(inputlen SHL 3));
  IF context.count[0]<(inputlen SHL 3) THEN INC(context.count[1]);
  INC(context.count[1],(inputlen SHR 29));

  partLen:=64-index;

  // Transform as many times as possible
  IF inputlen >= partLen THEN BEGIN
    MD5_memcpy(context,index,inputdata,0,partLen);
    MD5Transform(context.state,context.buffer);
    i:=partlen;
    WHILE (i+63)<inputlen DO BEGIN
      pB:=inputdata; Inc(pB,i);
      Move(pB^,work[0],64);
      MD5Transform(context.state,work);
      INC(i,64);
    END;
    index:=0;
  END ELSE
    i:=0;

  // Buffer remaining input
  MD5_memcpy(context,index,inputdata,i,inputlen-i);
end;

function  MD5Final(var context:TMD5_CTX):string;
var
  bits : array[0..7] of BYTE;
  work : string;
  index,padlen : DWORD;
  i,j : integer;
  procedure Encode8;
  begin
    i:=0; j:=0;
    WHILE j<8 DO BEGIN
      bits[j]:=context.count[i] AND $FF;
      bits[j+1]:=(context.count[i] SHR 8) AND $FF;
      bits[j+2]:=(context.count[i] SHR 16) AND $FF;
      bits[j+3]:=(context.count[i] SHR 24) AND $FF;
      INC(i); INC(j,4);
    END;
  end;
  function Encode16:string;
  begin
    result:='';
    i:=0; j:=0;
    WHILE j<16 DO BEGIN
      result:=result+IntToHex(context.state[i] AND $FF,2);
      result:=result+IntToHex((context.state[i] SHR 8) AND $FF,2);
      result:=result+IntToHex((context.state[i] SHR 16) AND $FF,2);
      result:=result+IntToHex((context.state[i] SHR 24) AND $FF,2);
      INC(i); INC(j,4);
    END;
    result:=LowerCase(result);
  end;
begin
  // Save number of bits
  Encode8;

  // Pad out to 56 mod 64
  index:=(context.count[0] SHR 3) AND $3F;
  IF index<56 THEN padlen:=56-index ELSE padlen:=120-index;
  MD5Update(context,PByte(@PADDING[1]),padlen);

  // Append length (before padding)
  work:='        '; // need 8byte
  Move(bits[0],work[1],8);
  MD5Update(context,pByte(@work[1]),8);

  // Store state in digest
  result:=Encode16;

  // Zeroize sensitive information.
  FillChar(context,sizeof(context),0);
end;

function CalcMD5(ASrc:PByte; ASize:integer):string;
var
  context : TMD5_CTX;
begin
  MD5Init(context);
  MD5Update(context,ASrc,ASize);
  result:=MD5Final(context);
end;

function CalcFileMD5_Sp(AFilename:string; ABreak:TMD5BreakFunc):string;
  function GetFSize(h:THandle):int64;
  var
    dwLowSize,dwHighSize : DWORD;
    cw0,cw1 : Int64;
  begin
    dwLowSize:=GetFileSize(h,@dwHighSize);
    IF (dwLowSize=$FFFFFFFF) AND (GetLastError<>NO_ERROR) THEN
      result:=-1
    ELSE BEGIN
      cw0:=dwLowSize;
      cw1:=dwHighSize;
      result:=cw0+cw1*$100000000;
    END;
  end;
const
  BUFSIZE = 4096*2;
var
  h : THANDLE;
  sz : DWORD;
  remain : INT64;
  buf : array[0..BUFSIZE-1] of BYTE;
  context : TMD5_CTX;
  done : boolean;
begin
  result:='';
  h:=CreateFile(PChar(AFilename),GENERIC_READ,FILE_SHARE_READ,
                nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
  IF h=INVALID_HANDLE_VALUE THEN Exit;
  try
    remain:=GetFSize(h);
    IF remain<>-1 THEN BEGIN
      // 最初
      done:=true;
      MD5Init(context);
      // 読み込み!
      WHILE remain>0 DO BEGIN
        IF NOT ReadFile(h,buf[0],BUFSIZE,sz,nil) THEN BEGIN
          done:=false; break;
        END;
        Dec(remain,sz);
        MD5Update(context,@buf[0],sz);
        IF Assigned(ABreak) AND ABreak THEN break;
      END;
      // 最後
      IF done THEN result:=MD5Final(context);
    END;
  finally
    CloseHandle(h);
  end;
end;

function CalcFileMD5(AFilename:string):string;
begin
  result:=CalcFileMD5_Sp(AFilename,nil);
end;

{$Q+}

end.
