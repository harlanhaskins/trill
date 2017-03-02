//
//  metadata.h
//  Trill
//
//  Created by Harlan Haskins on 9/2/16.
//  Copyright © 2016 Harlan. All rights reserved.
//

#ifndef metadata_h
#define metadata_h

#include "defines.h"
#include <stdint.h>
#include <stdio.h>

#ifdef __cplusplus
struct AnyBox;

namespace trill {
extern "C" {
#endif


/**
 `TRILL_ANY` is a special type understood by the Trill compiler as the
 representation of an `Any` value.
 */
typedef struct TRILL_ANY {
  void * _Nonnull _any;
#ifdef __cplusplus
  AnyBox *_Nonnull any() {
    return reinterpret_cast<AnyBox *>(_any);
  }
#endif
} TRILL_ANY;

/**
 Gets the formatted name of a given Trill type metadata object.

 @param typeMeta The type metadata.
 @return The name inside the type metadata. This is the same name
         that would appear in source code.
 */
const char *_Nonnull trill_getTypeName(const void *_Nonnull typeMeta);


/**
 Gets the size of type metadata in bits. This takes into account the specific
 LLVM sizing properties of the underlying type.

 @param typeMeta The type metadata.
 @return The size of the type, in bits, suitable for pointer arithmetic.
 */
uint64_t trill_getTypeSizeInBits(const void *_Nonnull typeMeta);


/**
 Determines whether or not this metadata represents a reference type, i.e.
 a type spelled `indirect type` in Trill.

 @param typeMeta The type metadata.
 @return A non-zero value if the metadata is a reference type, and 0
         otherwise.
 */
uint8_t trill_isReferenceType(const void *_Nonnull typeMeta);


/**
 Gets the number of fields from type metadata. Primitive types will have no
 fields, while record types (structs and tuples) will have fields.

 @param typeMeta The type metadata.
 @return The number of fields in this type.
 */
uint64_t trill_getNumFields(const void *_Nonnull typeMeta);


/**
 Gets the `FieldMetadata` associated with the provided field index into the
 provided `TypeMetadata`.
 
 @note This function will abort if the field index is out of bounds. Ensure
       the field you pass in is in-bounds by calling `trill_getNumFields` and
       comparing the result.

 @param typeMeta The type metadata.
 @param field The index of the field you wish to inspect.
 */
const void *_Nonnull trill_getFieldMetadata(const void *_Nonnull typeMeta,
                                             uint64_t field);


/**
 Gets the name of the provided `FieldMetadata`.

 @param fieldMeta The field metadata.
 @return A constant C string with the field's name as declared in the source.
 */
const char *_Nonnull trill_getFieldName(const void *_Nonnull fieldMeta);


/**
 Gets the `TypeMetadata` of the provided `FieldMetadata`.

 @param fieldMeta The field metadata.
 @return The metadata of the field's type.
 */
const void *_Nonnull trill_getFieldType(const void *_Nonnull fieldMeta);


/**
 Gets the offset of a field (in bytes) from the start of a type.

 @param fieldMeta The field metadata.
 @return The offset in bytes of a field in a composite type.
 */
size_t trill_getFieldOffset(const void *_Nullable fieldMeta);


/**
 Creates an `Any` representation with the provided type metadata.
 An `Any` in Trill is a variable-sized, heap-allocated box that holds:

 - Type metadata for the underlying object, and
 - A payload that is the size specified in the metadata.
 
 @note This value is uninitialized, and the payload will be empty. You
       must initialize the payload with a value by casting and storing
       the value into the pointer returned by `trill_getAnyValuePtr`.

 @param typeMeta The type metadata for the underlying value.
 @return A new `Any` box that is uninitialized.
 */
TRILL_ANY trill_allocateAny(const void *_Nonnull typeMeta);


/**
 Copies an `Any` if the underlying value's semantics mean it should be copied.
 If the underlying value is a reference type, then the provided `Any` is just
 returned unmodified.

 @param any The `Any` you wish to copy.
 @return A new `Any` containing the contents of the old `Any`, if the
         underlying value is has value semantics. Otherwise, the provided
         `Any`.
 */
TRILL_ANY trill_copyAny(TRILL_ANY any);

/**
 Gets a pointer to a field inside the `Any` structure. Specifically, this
 is a pointer inside the payload that will, when stored, update the value
 inside the payload.

 @note This function will abort if the field index is out of bounds. Ensure
       the field you pass in is in-bounds by calling `trill_getNumFields` and
       comparing the result.

 @param any_ The `Any` you're inspecting.
 @param fieldNum The field index you're accessing.
 @return A pointer into the payload that points to the value of the
         provided field.
 */
void *_Nonnull trill_getAnyFieldValuePtr(TRILL_ANY any_, uint64_t fieldNum);


/**
 Extracts a field from this payload and wraps it in its own `Any` container.
 

 @note This function will abort if the field index is out of bounds. Ensure
       the field you pass in is in-bounds by calling `trill_getNumFields` and
       comparing the result.

 @param any_ The composite type from which you're extracting a field.
 @param fieldNum The field index.
 @return A new `Any` with a payload that comes from the field's contents.
 */
TRILL_ANY trill_extractAnyField(TRILL_ANY any_, uint64_t fieldNum);


/**
 Updates a field with the value inside the provided `Any`.

 @param any_ The `Any` for the composite type whose field you are replacing.
 @param fieldNum The index of the field to be replaced.
 @param newAny_ The `Any` for the underlying field.
 */
void trill_updateAny(TRILL_ANY any_, uint64_t fieldNum, TRILL_ANY newAny_);


/**
 Gets a pointer to the payload that can be cast and stored.
 
 @note This will perform no casting or type checking for you, and should only
       be used opaquely or if you are absolutely sure of the underlying type.

 @param anyValue The `Any` whose payload you want to use.
 @return A pointer to the payload that can be cast and then loaded from.
 */
void *_Nonnull trill_getAnyValuePtr(TRILL_ANY anyValue);


/**
 Gets the `TypeMetadata` underlying an `Any` box.

 @param anyValue The `Any` box.
 @return The underlying type metadata.
 */
const void *_Nonnull trill_getAnyTypeMetadata(TRILL_ANY anyValue);


/**
 Checks if the underlying metadata of an `Any` matches the metadata provided.

 @param anyValue_ The `Any` whose type you're checking.
 @param typeMetadata_ The `TypeMetadata` you're checking.
 @return A non-zero value if the type metadata underlying the `Any` box
         is pointer-equal to the provided `TypeMetadata`. Otherwise, 0.
 */
uint8_t trill_checkTypes(TRILL_ANY anyValue_,
                         const void *_Nonnull typeMetadata_);


/**
 Checks if the underlying metadata of an `Any` box matches the provided
 metadata, and returns a pointer to the underlying payload if they do.
 
 @note If the `Any` value does not match the provided metadata, then this
       function causes a fatal error with a descriptive message and then
       aborts with a stack trace.

 @param anyValue_ The `Any` you're trying to cast.
 @param typeMetadata_ The `TypeMetadata` you're checking the `Any` against.
 @return A pointer to the payload that is safe to cast based on the type
         metadata.
 */
const void *_Nonnull trill_checkedCast(TRILL_ANY anyValue_,
                                       const void *_Nonnull typeMetadata_);


/**
 Determines if the value underlying an `Any` is `nil`. If the type underlying
 the `Any` is not a pointer or indirect type, then this will always return
 `false`. However, if the underlying value is a pointer or indirect type, then
 this function will read the payload and see if the value in the payload is
 `NULL`.

 @param any_ The `Any` you're checking.
 @return A non-zero value if the underlying payload should be interpreted as a
         `nil` value.
 */
uint8_t trill_anyIsNil(TRILL_ANY any_);


#ifdef __cplusplus
}
}
#endif

#endif /* metadata_h */
