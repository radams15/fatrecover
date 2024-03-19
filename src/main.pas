program FatRecover;

{$mode Delphi}

uses
    sysutils,
    classes;

const
    DeletedByte: byte = $E5;

type

    DirEnt = record
        fullName: Array [0..10] of uint8;

        reserved: uint8;
        attrib: uint8;
        userAttrib: uint8;

        createTime: uint16;
        createDate: uint16;
        accessDate: uint16;

        clusterHigh: uint16;

        modifiedTime: uint16;
        modifiedDate: uint16;

        cluster: uint16;
        fileSize: uint32;
    end;

    Cluster = Array[0..127] of uint32;
    ClusterFile = File of Cluster;
    DirEntFile = File of DirEnt;

    procedure PrintFatCluster(var imgFile: ClusterFile ; clusterNum: uint32);
    var
        clusterValue: Cluster;
        i: uint32;
    begin
        Reset(imgFile);
        Seek(imgFile, $1028 + clusterNum);
        Read(imgFile, clusterValue);
        WriteLn(Format(#9'%x', [clusterNum]));

        for i := 0 to 128 do
        begin
            Write(Format('%c', [clusterValue[i]]));
        end;
        WriteLn('');
    end;

    procedure ReadClusterChain(var imgFile: ClusterFile ; dirFile: DirEnt ; fat: Cluster);
    var
        fatVal: uint32;
        i: uint32;
    begin
        fatVal := dirFile.cluster;
        for i:=0 to 32 do
        begin
            PrintFatCluster(imgFile, fatVal);
            fatVal := fat[fatVal] AND $0FFFFFFF;
            if fatVal >= $0FFFFFF7 then Exit;
        end;
    end;

    function ReadDirEnt(var imgFile: DirEntFile ; fat: Cluster) : DirEnt;
    var
        rootDir: DirEnt;
        name: String;
    begin
        Read(imgFile, rootDir);

        if rootDir.fullName[0] = DeletedByte then
        begin
            { Is deleted }
            rootDir.fullName[0] := Byte('_');
        end;

        name := StrPas(@rootDir.fullName);

        if length(name) = 0 then
        begin
            Result.fullName[0] := Byte(0);
            Exit;
        end;

        ReadDirEnt := rootDir;


    end;

    function ReadFat(var imgFile: ClusterFile) : Cluster;
    var
        fat: Cluster;
    begin
        Reset(imgFile);
        Seek(imgFile, $20);

        Read(imgFile, fat);

        ReadFat := fat;
    end;

    function ReadDir(var dirFile: DirEntFile ; fat: Cluster) : TArray<DirEnt>;
    var
        i: uint32;
        fileEnt: DirEnt;
    begin
        Reset(dirFile);
        Seek(dirFile, $10200);

        Result := TArray<DirEnt>.Create;

        for i := 0 to 32 do
        begin
            fileEnt := ReadDirEnt(dirFile, fat);

            if fileEnt.fullName[0] <> 0 then
            begin
                SetLength(Result, Length(Result)+1);

                Result[High(Result)] := fileEnt;
            end;
        end;
    end;

    procedure ReadFile(fileName: String);
    var
        imgFile: ClusterFile;
        fat: Cluster;
        files: TArray<DirEnt>;
        dirFile: DirEnt;
        dirFileName: String;
    begin
        AssignFile(imgFile, fileName);

        fat := ReadFat(imgFile);
        files := ReadDir(DirEntFile(imgFile), fat);

        for dirFile in files do
        begin
            dirFileName := StrPas(@dirFile.fullName);

            WriteLn(Format('%s => %x bytes @ cluster %x', [dirFileName, dirFile.fileSize, dirFile.cluster]));

            ReadClusterChain(ClusterFile(imgFile), dirFile, fat);
        end;
    end;

begin
    ReadFile('test.img');
end.
