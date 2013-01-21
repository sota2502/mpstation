unit Crypt;

{
    データの暗号化
    function Encrypt(
        CData: TCryptData;
        Entropy: String = '';
        LocalMachine: Boolean = False
    ): String;

    データの復号化
    function Decrypt(
        Source: String;
        Entropy: String = ''
    ): TCryptData;
}


interface

uses
    Windows, Classes, SysUtils;

type  
    _CRYPTOAPI_BLOB = record
        cbData: DWORD;
        pbData: PBYTE;
    end;
    {$EXTERNALSYM _CRYPTOAPI_BLOB}

    DATA_BLOB = _CRYPTOAPI_BLOB;
    {$EXTERNALSYM DATA_BLOB}
    PDATA_BLOB = ^DATA_BLOB;
    {$EXTERNALSYM PDATA_BLOB}

    PCRYPTPROTECT_PROMPTSTRUCT = ^CRYPTPROTECT_PROMPTSTRUCT;
    {$EXTERNALSYM PCRYPTPROTECT_PROMPTSTRUCT}
    _CRYPTPROTECT_PROMPTSTRUCT = record
        cbSize: DWORD;
        dwPromptFlags: DWORD;
        hwndApp: HWND;
        szPrompt: LPCWSTR;
    end;
    {$EXTERNALSYM _CRYPTPROTECT_PROMPTSTRUCT}
    CRYPTPROTECT_PROMPTSTRUCT = _CRYPTPROTECT_PROMPTSTRUCT;
    {$EXTERNALSYM CRYPTPROTECT_PROMPTSTRUCT}

    TBytes = array of Byte;
    TCryptData = record
        Data:        String;
        Description: String;
    end;
const
    CRYPTPROTECT_LOCAL_MACHINE = $4;
    {$EXTERNALSYM CRYPTPROTECT_LOCAL_MACHINE}

function Encrypt(
    CData: TCryptData;
    Entropy: String = '';
    LocalMachine: Boolean = False
): String;

function Decrypt(
    Source: String;
    Entropy: String = ''
): TCryptData;

function CryptData(
    Data:        String;
    Description: String
): TCryptData;

implementation

function CryptProtectData(pDataIn: PDATA_BLOB; szDataDescr: PWideChar;
                          pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
                          pPromptStruct: PCRYPTPROTECT_PROMPTSTRUCT;
                          dwFlags: DWORD; pDataOut: PDATA_BLOB): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptProtectData';
{$EXTERNALSYM CryptProtectData}

function CryptUnprotectData(pDataIn: PDATA_BLOB; var ppszDataDescr: PWideChar;
                            pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
                            pPromptStruct: PCRYPTPROTECT_PROMPTSTRUCT;
                            dwFlags: DWORD; pDataOut: PDATA_BLOB): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptUnprotectData';
{$EXTERNALSYM CryptUnprotectData}


function BinToStr(P: PByte; Size: DWORD): String;
begin
    SetLength(Result, Size * 2);
    BinToHex(PChar(P), PChar(Result), Size);
end;


function StrToBin(const S: String): TBytes;
var Size: Integer;
    b: TBytes;
begin
    Size := Length(S) div 2;
    SetLength(b, Size);
    HexToBin(PChar(S), PChar(b), Size);
    Result := b;
end;


function Encrypt(
    CData: TCryptData;
    Entropy: String;
    LocalMachine: Boolean
): String;
var
    DataIn, DataOut, OptionalEntropy: DATA_BLOB;
    POptionalEntropy: PDATA_BLOB;
{$IFDEF Unicode}
    WDescription: String;
{$ELSE}
    WDescription: WideString;
{$ENDIF}
    Flags: DWORD;
    MemorySource: TMemoryStream;
    MemoryEntropy: TMemoryStream;
begin

    MemorySource := nil;
    MemoryEntropy := nil;
    try
        MemorySource := TMemoryStream.Create;
        MemoryEntropy := TMemoryStream.Create;

        { DataIn }
        with MemorySource do
        begin
            Write(PChar(CData.Data)^,Length(CData.Data) * SizeOf(Char));
            DataIn.cbData := Size;
            DataIn.pbData := Memory;
        end;

        { OptionalEntropy }
        if Entropy = '' then
        begin
            POptionalEntropy := nil;
        end
        else
        begin
            with MemoryEntropy do
            begin
                Write(PChar(Entropy)^,Length(Entropy) * SizeOf(Char));
                OptionalEntropy.cbData := Size;
                OptionalEntropy.pbData := Memory;
            end;
            POptionalEntropy := @OptionalEntropy;
        end;

        { Description }
        WDescription := CData.Description;

        { Flags }
        Flags := 0;
        if LocalMachine = True then
        begin
            Flags := CRYPTPROTECT_LOCAL_MACHINE;
        end;

        { DataOut }
        FillChar(DataOut,SizeOf(DataOut),0);

        { Protect data }
        if CryptProtectData(@DataIn,PWideChar(WDescription),POptionalEntropy,nil,
                                                nil,Flags,@DataOut) = False then
        begin
            RaiseLastOSError;
        end;

        { Result }
        Result := BinToStr(DataOut.pbData,DataOut.cbData);

        { Free allocated memory }
        LocalFree(HLOCAL(DataOut.pbData));

    finally
        MemorySource.Free;
        MemoryEntropy.Free;
    end;

end;

function Decrypt(Source: String; Entropy: String): TCryptData;
var
    DataIn, DataOut, OptionalEntropy: DATA_BLOB;
    POptionalEntropy: PDATA_BLOB;
    PDescription: PWideChar;
    MemoryEntropy: TMemoryStream;
    b: TBytes;
begin
    MemoryEntropy := TMemoryStream.Create;
    try

        { DataIn }
        b := StrToBin(Source);
        DataIn.cbData := Length(b);
        DataIn.pbData := PByte(b);

        { OptionalEntropy }
        if Entropy = '' then
        begin
            POptionalEntropy := nil;
        end
        else
        begin
            with MemoryEntropy do
            begin
                Write(PChar(Entropy)^,Length(Entropy) * SizeOf(Char));
                OptionalEntropy.cbData := Size;
                OptionalEntropy.pbData := Memory;
            end;
            POptionalEntropy := @OptionalEntropy;
        end;

        { DataOut }
        FillChar(DataOut,SizeOf(DataOut),0);

        { Unprotect data }
        if CryptUnprotectData(@DataIn,PDescription,POptionalEntropy,nil,
                                                    nil,0,@DataOut) = False then
        begin
            RaiseLastOSError;
        end;

        { Result }
        SetString(Result.Data, PChar(DataOut.pbData), DataOut.cbData div SizeOf(Char));

        { Description }
        Result.Description := PDescription;

        { Free allocated memory }
        LocalFree(HLOCAL(DataOut.pbData));
        LocalFree(HLOCAL(PDescription));
    finally
        MemoryEntropy.Free;
    end;

end;


function CryptData(Data: String; Description: String): TCryptData;
begin
    Result.Data        := Data;
    Result.Description := Description;
end;



end.
