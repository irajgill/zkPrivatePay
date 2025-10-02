// Noir KYC selective disclosure (skeleton)
fn main(min_age: Field, age: Field) {
    constrain age >= min_age;
}
