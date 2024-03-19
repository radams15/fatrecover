program FatRecover;

{$mode Delphi}

uses
    sysutils;

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

    procedure ReadClusterChain(dirFile: DirEnt ; fat: Cluster);
    var
        fatVal: uint32;
        i: uint32;
    begin
        for i:=0 to 16 do
        begin
            fatVal := fat[i] AND $0FFFFFFF;
            WriteLn(Format('%x => %x', [i, fatVal]));
        end;
    end;

    procedure PrintDirEnt(var imgFile: DirEntFile ; fat: Cluster);
    var
        rootDir: DirEnt;
        name: String;
    begin
        Read(imgFile, rootDir);

        if rootDir.fullName[0] = DeletedByte then
        begin
            //Write('Deleted: ');
            rootDir.fullName[0] := Byte('_');
        end;

        name := StrPas(@rootDir.fullName);

        if length(name) = 0 then
        begin
            Exit;
        end;

        WriteLn(Format('%s => %x bytes @ cluster %x', [name, rootDir.fileSize, rootDir.cluster]));

        ReadClusterChain(rootDir, fat);
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

    procedure ReadDir(var dirFile: DirEntFile ; fat: Cluster);
    var
        i: uint32;
    begin
        Reset(dirFile);
        Seek(dirFile, $10200);

        for i := 0 to 32 do
        begin
            PrintDirEnt(dirFile, fat);
        end;
    end;

    procedure ReadFile(fileName: String);
    var
        imgFile: ClusterFile;
        fat: Cluster;
    begin
        AssignFile(imgFile, fileName);

        fat := ReadFat(imgFile);
        ReadDir(DirEntFile(imgFile), fat);
    end;

begin
    ReadFile('test.img');
end.
