## Nullish
```javascript
class Foo {
    name;
    constructor(rawName?: string) {
        // only if rawName is null or undefined, fallback will happen
        this.name = rawName ?? '(no name)'
        // empty string, 0 or false will also fallback to (no name)
        this.name = rawName || '(no name)'
    }
}
```

## Private Fields
- TypeScript Version: > 3.8
```javascript
class Animal {
    #name: string;
    constructor(theName: string){
        this.#name = theName;
    }
}
```

## Tuple types
```javascript
type Address = [
    streetNumber: number, 
    city: string, 
    state: string, 
    postal: number
]

function printAddress(...address: Address){}
```

## Nested Type
- TypeScript Version: > 4.0
```javascript
type JSONValue = 
    | string
    | number
    | boolean
    | null
    | JSONValue[]
    | {
        [k:string]: JSONValue
    }

const val: JSONValue = {
    name: 'mike',
    address: {
        street: 'Super St'
    }
}
```

## Better alternative to `@ts-ignore`
```javascript
// @ts-expect-error
const num1:number = 5; // will give error is everything is right
// @ts-ignore
const num2:number = 5;
```

## `unknown` type
- explicitly say you need to check type manually
```javascript
try {
    somethingRisky()
} catch(err: unknown) {
    if (err instanceof Error){
        console.log(err.stack);
    } else {
        console.log(err);
    }
}
```

## Check JavaScript
- first, you need to enable `check-js` in `tsconfig.json`
```javascript
/** @type {number} */
var x;

x = 0;      // OK
x = false;  // Error: boolean is not assignable to number
```

## Import type only
- will actually bring no code to runtime.
```javascript
import type { SomeThing } from './some-module.js';
export type { SomeThing };
```