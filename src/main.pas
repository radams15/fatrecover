program FatRecover;

{$mode Delphi}

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

    procedure ReadFile(fileName: String);
    var
        imgFile: File of DirEnt;
        rootDir: DirEnt;
        name: String;
        i: uint32;
    begin
        AssignFile(imgFile, fileName);
        Reset(imgFile);
        Seek(imgFile, $10200);

        for i:=0 to 32 do
        begin
            Read(imgFile, rootDir);

            if rootDir.fullName[0] = $E5 then
                Write('Deleted: ');

            name := StrPas(@rootDir.fullName);

            WriteLn(name);
        end;
    end;

begin

    ReadFile('../test.img');

end.
