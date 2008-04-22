{
@abstract(Contains structures to support auto free class instances.)
@author(Christian Wimmer)
@created(03/23/2007)
@lastmod(09/10/2007)



Project JEDI Windows Security Code Library (JWSCL)

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy of the
License at http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
ANY KIND, either express or implied. See the License for the specific language governing rights
and limitations under the License.

Alternatively, the contents of this file may be used under the terms of the  
GNU Lesser General Public License (the  "LGPL License"), in which case the   
provisions of the LGPL License are applicable instead of those above.        
If you wish to allow use of your version of this file only under the terms   
of the LGPL License and not to allow others to use your version of this file 
under the MPL, indicate your decision by deleting  the provisions above and  
replace  them with the notice and other provisions required by the LGPL      
License.  If you do not delete the provisions above, a recipient may use     
your version of this file under either the MPL or the LGPL License.          
                                                                             
For more information about the LGPL: http://www.gnu.org/copyleft/lesser.html 

The Original Code is JwsclComUtils.pas.

The Initial Developer of the Original Code is Robert Giesecke.

TODO: 
Same for FreeMem, and so on

To use this code simply to the follwoing:
@longCode(#
var myClass : TMyClass;
begin
  myClass := TMyClass.Create;
  TJwAutoPointer.Wrap(myClass);

  ... your code here ...
end; //autodestruction of myClass here.
#)


}
{$IFNDEF SL_OMIT_SECTIONS}
unit JwsclComUtils;
// Last modified: $Date: 2007-09-10 10:00:00 +0100 $

interface

uses
  Classes, JwsclTypes, JwsclResource ,Jwsclexceptions;
{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_IMPLEMENTATION_SECTION}
const
  IIDIJwAutoPointer = '{08360FA5-F278-45EF-98FE-6C43DF9C778B}';
  IIDIJwAutoLock = '{555DB592-48B3-4E37-8853-E50A33E869A3}';

type
  IJwAutoPointer = interface;

  IJwAutoLock = interface
  [IIDIJwAutoLock]
    function GetAutoPointer : IJwAutoPointer;
    function GetPointer   : Pointer;
    function GetInstance  : TObject;
    function GetPointerType : TJwPointerType;

    procedure UnLock;

    property Pointer   : Pointer read GetPointer;
    property Instance  : TObject read GetInstance;
    property PointerType  : TJwPointerType read GetPointerType;
  end;

  IJwAutoPointer = interface
  [IIDIJwAutoPointer]
    function GetPointer   : Pointer;
    function GetInstance  : TObject;
    function GetPointerType : TJwPointerType;
    property Pointer   : Pointer read GetPointer;
    property Instance  : TObject read GetInstance;
    property PointerType  : TJwPointerType read GetPointerType;

    function Lock : IJwAutoLock;
  end;

  {@Name implements tool functions for creating new and wrapping existing
   pointers and classes for auto destruction. }
  TJwAutoPointer = class
    {@Name wraps an existing class instance for auto pointer desctruction.
     When the returned auto pointer interface goes out of scope the
     given instance will be destroyed.
    @param(Instance defines the class instance that will be automatically
     destroyed)
    @return(Returns an auto pointer interface that is resposible for
      auto destruction.)}
    class function Wrap(const Instance  : TObject) : IJwAutoPointer; overload;

    {@Name wraps an existing pointer for auto desctruction.
     When the returned auto pointer interface goes out of scope the
     given pointer will be destroyed.
     @param(Ptr Defines a pointer that is automatically destroyed.)
     @param(Size Defines the size of the pointer data. If size is
        not zero, the memory will be overwritten with zeroes before
        it is freed.)
     @param(PointerType Defines the pointer type. It is used to call
      the appropriate free function.)
     @return(Returns an auto pointer interface that is resposible for
      auto destruction.)
     }
    class function Wrap(const Ptr : Pointer;
        Size : Cardinal;
        PointerType : TJwPointerType) : IJwAutoPointer; overload;

    {@Name creates a new auto pointer class instance and also
     creates the given class with a default constructor (no parameters).
     Use instead Wrap if you cannot use standard constructor or
      your class does not support a standard constructor.
     @param(ClassReference defines the class type which is to be created)
     @return(Returns an auto pointer interface that is resposible for
      auto destruction.)
     }
    class function CreateInstance(
      const ClassReference : TClass) : IJwAutoPointer; overload;

    {@Name creates a new auto pointer class instance and also
     creates the given component class.
     Use instead Wrap if you cannot use standard component constructor or
      your class does not support a standard component constructor.
     @param(ClassReference defines the class type which is to be created)
     @param(Owner defines the component owner which is applied to the
      component constructor.)
     @return(Returns an auto pointer interface that is resposible for
      auto destruction.)
     }
    class function CreateInstance(
      const ClassReference : TComponentClass;
      const Owner          : TComponent = nil) : IJwAutoPointer; overload;

    {@Name creates a new pointer or wraps an existing one.
     The following pointer types are created automatically :
      @unorderedlist(
        @item(ptGetMem)
        @item(ptLocalAlloc)
      )
     The following pointer types are tunneled through and must
     be created by the caller:
      @unorderedlist(
        @item(ptNew )
      )
     The following pointer types are not supported and raises EJwsclInvalidPointerType
      @unorderedlist(
        @item(ptUnknown)
        @item(ptClass)
      )

     }
    class function CreateNewPointer(
      var Ptr : Pointer; Size : Cardinal; PointerType : TJwPointerType)  : IJwAutoPointer; overload;
  end;

{$ENDIF SL_IMPLEMENTATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
implementation
uses JwaWindows, SysUtils, SyncObjs;
{$ENDIF SL_OMIT_SECTIONS}


{$IFNDEF SL_INTERFACE_SECTION}
type
  TJwAutoPointerImpl = class(TInterfacedObject, IJwAutoPointer)
  protected
    fInstance : TObject;
    fPointer : Pointer;
    fPointerType : TJwPointerType;
    fSize : Cardinal;
    fSection : TCriticalSection;

    function GetInstance: TObject;
    function GetPointer: Pointer;
    function GetPointerType : TJwPointerType;
  public
    constructor Create(const Instance : TObject); overload;
    constructor Create(const Ptr : Pointer; Size : Cardinal; PointerType : TJwPointerType); overload;
    procedure BeforeDestruction; override;

    function Lock : IJwAutoLock;
  end;

  TJwAutoLock = class(TInterfacedObject, IJwAutoLock)
  protected
    fAutoPointer : TJwAutoPointerImpl;
    fLeaveFlag : Boolean;
  public
    constructor Create(const AutoPointer : TJwAutoPointerImpl);

    function GetAutoPointer : IJwAutoPointer;
    function GetPointer   : Pointer;
    function GetInstance  : TObject;
    function GetPointerType : TJwPointerType;

    procedure BeforeDestruction;

    procedure UnLock;
  end;


{ AutoPointer }

class function TJwAutoPointer.Wrap(const Instance: TObject): IJwAutoPointer;
begin
  Result := TJwAutoPointerImpl.Create(instance);
end;

class function TJwAutoPointer.CreateInstance(
  const ClassReference : TClass): IJwAutoPointer;
begin
  Result := Wrap(classReference.Create());
end;

class function TJwAutoPointer.CreateInstance(
  const ClassReference : TComponentClass;
  const Owner : TComponent): IJwAutoPointer;
begin
  Result := Wrap(classReference.Create(Owner));
end;


class function TJwAutoPointer.CreateNewPointer(
  var Ptr : Pointer; Size : Cardinal; PointerType: TJwPointerType): IJwAutoPointer;
begin
  case PointerType of
    ptGetMem : GetMem(Ptr, Size);
    ptLocalAlloc : Ptr := Pointer(LocalAlloc(LPTR,Size));
    ptNew : Size := 0;
    ptUnknown,
    ptClass:
    raise EJwsclInvalidPointerType.CreateFmtEx(
      RsInvalidPointerType, 'CreateNewPointer', ClassName, RsUNComUtils,
      0, False, []);
  end;
  Result := Wrap(Ptr, Size, PointerType);
end;

class function TJwAutoPointer.Wrap(const Ptr: Pointer;
  Size : Cardinal;
  PointerType: TJwPointerType): IJwAutoPointer;
begin
  Result := TJwAutoPointerImpl.Create(Ptr, Size, PointerType);
end;

{ TAutoPinterImpl }

function TJwAutoPointerImpl.GetInstance : TObject;
begin
  Result := fInstance;
end;

function TJwAutoPointerImpl.GetPointer : Pointer;
begin
  Result := fInstance;
end;

procedure TJwAutoPointerImpl.BeforeDestruction;
begin
  fSection.Enter;

  try
    case fPointerType of
      ptGetMem : if fSize <> 0 then ZeroMemory(fPointer, fSize);
      ptLocalAlloc : if fSize <> 0 then ZeroMemory(fPointer, fSize);
    end;

    case fPointerType of
      ptClass  : fInstance.Free();
      ptGetMem : FreeMem(fPointer);
      ptLocalAlloc : LocalFree(Cardinal(fPointer));
      ptNew : Dispose(fPointer);
    end;

    fPointer := nil;
    fInstance := nil;
  finally
    fSection.Leave;
    FreeAndNil(fSection);
  end;

  inherited;
end;

constructor TJwAutoPointerImpl.Create(const Instance : TObject);
begin
  fInstance := Instance;
  fPointerType := ptClass;
  fSection := TCriticalSection.Create;
end;

constructor TJwAutoPointerImpl.Create(const Ptr: Pointer;
  Size : Cardinal;
  PointerType: TJwPointerType);
begin
  fPointer := Ptr;
  fPointerType := PointerType;
  fSize := Size;
  fSection := TCriticalSection.Create;
end;

function TJwAutoPointerImpl.GetPointerType: TJwPointerType;
begin
  result := fPointerType;
end;


function TJwAutoPointerImpl.Lock: IJwAutoLock;
begin
  result := TJwAutoLock.Create(Self);
end;


{ TJwAutoLock }

procedure TJwAutoLock.BeforeDestruction;
begin
  if Assigned(fAutoPointer.fSection) and not fLeaveFlag then
    fAutoPointer.fSection.Leave;

  inherited;
end;

constructor TJwAutoLock.Create(const AutoPointer: TJwAutoPointerImpl);
begin
  AutoPointer.fSection.Enter;

  fAutoPointer := AutoPointer;
  fLeaveFlag := false;

  inherited Create;
end;

function TJwAutoLock.GetAutoPointer: IJwAutoPointer;
begin
  result := fAutoPointer;
end;

function TJwAutoLock.GetInstance: TObject;
begin
  result := fAutoPointer.GetInstance;
end;

function TJwAutoLock.GetPointer: Pointer;
begin
  result := fAutoPointer.GetPointer;
end;

function TJwAutoLock.GetPointerType: TJwPointerType;
begin
  result := fAutoPointer.GetPointerType;
end;

procedure TJwAutoLock.UnLock;
begin
  if Assigned(fAutoPointer.fSection) then
    fAutoPointer.fSection.Leave;
  fLeaveFlag := true;
end;

{$ENDIF SL_INTERFACE_SECTION}


{$IFNDEF SL_OMIT_SECTIONS}





initialization
{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_INITIALIZATION_SECTION}
{$ENDIF SL_INITIALIZATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
end.
{$ENDIF SL_OMIT_SECTIONS}