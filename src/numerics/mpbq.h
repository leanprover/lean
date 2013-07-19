/*
Copyright (c) 2013 Microsoft Corporation. All rights reserved. 
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura 
*/
#pragma once
#include "mpz.h"
#include "mpq.h"

namespace lean {

// Multiple precision binary rationals 
class mpbq {
    mpz      m_num;
    unsigned m_k;
    void normalize();
    template<typename T> mpbq & add_int(T const & a);
    template<typename T> mpbq & sub_int(T const & a);
    template<typename T> mpbq & mul_int(T const & a);
public:
    mpbq():m_k(0) {}
    mpbq(mpbq const & v):m_num(v.m_num), m_k(v.m_k) {}
    mpbq(mpbq && v);
    mpbq(mpz const & v):m_num(v), m_k(0) {}
    mpbq(int n):m_num(n), m_k(0) {}
    mpbq(int n, unsigned k):m_num(n), m_k(k) { normalize(); }
    ~mpbq() {}

    mpbq & operator=(mpbq const & v) { m_num = v.m_num; m_k = v.m_k; return *this; }
    mpbq & operator=(mpbq && v) { swap(v); return *this; }
    mpbq & operator=(unsigned int v) { m_num = v; m_k = 0; return *this; }
    mpbq & operator=(int v) { m_num = v; m_k = 0; return *this; }

    void swap(mpbq & o) { m_num.swap(o.m_num); std::swap(m_k, o.m_k); }

    unsigned hash() const { return m_num.hash(); }

    int sgn() const { return m_num.sgn(); }
    friend int sgn(mpbq const & a) { return a.sgn(); }
    bool is_pos() const { return sgn() > 0; } 
    bool is_neg() const { return sgn() < 0; }
    bool is_zero() const { return sgn() == 0; }
    bool is_nonpos() const { return !is_pos(); }
    bool is_nonneg() const { return !is_neg(); }

    void neg() { m_num.neg(); }
    friend mpbq neg(mpbq a) { a.neg(); return a; }

    void abs() { m_num.abs(); }
    friend mpbq abs(mpbq a) { a.abs(); return a; }

    mpz const & get_numerator() const { return m_num; }
    unsigned get_k() const { return m_k; }
    bool is_integer() const { return m_k == 0; }
    
    friend int cmp(mpbq const & a, mpbq const & b);
    friend int cmp(mpbq const & a, mpz const & b);
    friend int cmp(mpbq const & a, mpq const & b);
    friend int cmp(mpbq const & a, unsigned b) { return cmp(a, mpbq(b)); }
    friend int cmp(mpbq const & a, int b) { return cmp(a, mpbq(b)); }

    friend bool operator<(mpbq const & a, mpbq const & b) { return cmp(a, b) < 0; } 
    friend bool operator<(mpbq const & a, mpz const & b) { return cmp(a, b) < 0; } 
    friend bool operator<(mpbq const & a, mpq const & b) { return cmp(a, b) < 0; } 
    friend bool operator<(mpbq const & a, unsigned b) { return cmp(a, b) < 0; } 
    friend bool operator<(mpbq const & a, int b) { return cmp(a, b) < 0; }     
    friend bool operator<(mpz const & a, mpbq const & b) { return cmp(b, a) > 0; }     
    friend bool operator<(mpq const & a, mpbq const & b) { return cmp(b, a) > 0; }     
    friend bool operator<(unsigned a, mpbq const & b) { return cmp(b, a) > 0; } 
    friend bool operator<(int a, mpbq const & b) { return cmp(b, a) > 0; }     

    friend bool operator>(mpbq const & a, mpbq const & b) { return cmp(a, b) > 0; } 
    friend bool operator>(mpbq const & a, mpz const & b) { return cmp(a, b) > 0; } 
    friend bool operator>(mpbq const & a, mpq const & b) { return cmp(a, b) > 0; } 
    friend bool operator>(mpbq const & a, unsigned b) { return cmp(a, b) > 0; } 
    friend bool operator>(mpbq const & a, int b) { return cmp(a, b) > 0; }     
    friend bool operator>(mpz const & a, mpbq const & b) { return cmp(b, a) < 0; }     
    friend bool operator>(mpq const & a, mpbq const & b) { return cmp(b, a) < 0; }     
    friend bool operator>(unsigned a, mpbq const & b) { return cmp(b, a) < 0; } 
    friend bool operator>(int a, mpbq const & b) { return cmp(b, a) < 0; }     

    friend bool operator<=(mpbq const & a, mpbq const & b) { return cmp(a, b) <= 0; } 
    friend bool operator<=(mpbq const & a, mpz const & b) { return cmp(a, b) <= 0; } 
    friend bool operator<=(mpbq const & a, mpq const & b) { return cmp(a, b) <= 0; } 
    friend bool operator<=(mpbq const & a, unsigned b) { return cmp(a, b) <= 0; } 
    friend bool operator<=(mpbq const & a, int b) { return cmp(a, b) <= 0; }     
    friend bool operator<=(mpz const & a, mpbq const & b) { return cmp(b, a) >= 0; }     
    friend bool operator<=(mpq const & a, mpbq const & b) { return cmp(b, a) >= 0; }     
    friend bool operator<=(unsigned a, mpbq const & b) { return cmp(b, a) >= 0; } 
    friend bool operator<=(int a, mpbq const & b) { return cmp(b, a) >= 0; }     

    friend bool operator>=(mpbq const & a, mpbq const & b) { return cmp(a, b) >= 0; } 
    friend bool operator>=(mpbq const & a, mpz const & b) { return cmp(a, b) >= 0; } 
    friend bool operator>=(mpbq const & a, mpq const & b) { return cmp(a, b) >= 0; } 
    friend bool operator>=(mpbq const & a, unsigned b) { return cmp(a, b) >= 0; } 
    friend bool operator>=(mpbq const & a, int b) { return cmp(a, b) >= 0; }     
    friend bool operator>=(mpz const & a, mpbq const & b) { return cmp(b, a) <= 0; }     
    friend bool operator>=(mpq const & a, mpbq const & b) { return cmp(b, a) <= 0; }     
    friend bool operator>=(unsigned a, mpbq const & b) { return cmp(b, a) <= 0; } 
    friend bool operator>=(int a, mpbq const & b) { return cmp(b, a) <= 0; }     

    friend bool operator==(mpbq const & a, mpbq const & b) { return a.m_k == b.m_k && a.m_num == b.m_num; }
    friend bool operator==(mpbq const & a, mpz const & b) { return a.is_integer() && a.m_num == b; }
    friend bool operator==(mpbq const & a, mpq const & b) { return cmp(a, b) == 0; }
    friend bool operator==(mpbq const & a, unsigned int b) { return a.is_integer() && a.m_num == b; }
    friend bool operator==(mpbq const & a, int b) { return a.is_integer() && a.m_num == b; }
    friend bool operator==(mpz const & a, mpbq const & b) { return operator==(b, a); }
    friend bool operator==(mpq const & a, mpbq const & b) { return operator==(b, a); }
    friend bool operator==(unsigned int a, mpbq const & b) { return operator==(b, a); }
    friend bool operator==(int a, mpbq const & b) { return operator==(b, a); }

    friend bool operator!=(mpbq const & a, mpbq const & b) { return !operator==(a,b); }
    friend bool operator!=(mpbq const & a, mpz const & b) { return !operator==(a,b); }
    friend bool operator!=(mpbq const & a, mpq const & b) { return !operator==(a,b); }
    friend bool operator!=(mpbq const & a, unsigned int b) { return !operator==(a,b); }
    friend bool operator!=(mpbq const & a, int b) { return !operator==(a,b); }
    friend bool operator!=(mpz const & a, mpbq const & b) { return !operator==(a,b); }
    friend bool operator!=(mpq const & a, mpbq const & b) { return !operator==(a,b); }
    friend bool operator!=(unsigned int a, mpbq const & b) { return !operator==(a,b); }
    friend bool operator!=(int a, mpbq const & b) { return !operator==(a,b); }

    mpbq & operator+=(mpbq const & a);
    mpbq & operator+=(unsigned a);
    mpbq & operator+=(int a);

    mpbq & operator-=(mpbq const & a);
    mpbq & operator-=(unsigned a);
    mpbq & operator-=(int a);

    mpbq & operator*=(mpbq const & a);
    mpbq & operator*=(unsigned a);
    mpbq & operator*=(int a);

    friend mpbq operator+(mpbq a, mpbq const & b) { return a += b; } 
    friend mpbq operator+(mpbq a, mpz const & b) { return a += b; } 
    friend mpbq operator+(mpbq a, unsigned b)  { return a += b; }         
    friend mpbq operator+(mpbq a, int b)  { return a += b; }              
    friend mpbq operator+(mpz const & a, mpbq b) { return b += a; }
    friend mpbq operator+(unsigned a, mpbq b) { return b += a; }          
    friend mpbq operator+(int a, mpbq b) { return b += a; }               

    friend mpbq operator-(mpbq a, mpbq const & b) { return a -= b; } 
    friend mpbq operator-(mpbq a, mpz const & b) { return a -= b; } 
    friend mpbq operator-(mpbq a, unsigned b) { return a -= b; }          
    friend mpbq operator-(mpbq a, int b) { return a -= b; }               
    friend mpbq operator-(mpz const & a, mpbq b) { b.neg(); return b += a; }
    friend mpbq operator-(unsigned a, mpbq b) { b.neg(); return b += a; } 
    friend mpbq operator-(int a, mpbq b) { b.neg(); return b += a; }      

    friend mpbq operator*(mpbq a, mpbq const & b) { return a *= b; }
    friend mpbq operator*(mpbq a, mpz const & b) { return a *= b; }
    friend mpbq operator*(mpbq a, unsigned b) { return a *= b; }          
    friend mpbq operator*(mpbq a, int b) { return a *= b; }               
    friend mpbq operator*(mpz const & a, mpbq b) { return b *= a; }
    friend mpbq operator*(unsigned a, mpbq b) { return b *= a; }          
    friend mpbq operator*(int a, mpbq b) { return b *= a; }

    mpbq & operator++() { return operator+=(1); }
    mpbq operator++(int) { mpbq r(*this); ++(*this); return r; }

    mpbq & operator--() { return operator-=(1); }
    mpbq operator--(int) { mpbq r(*this); --(*this); return r; }

    friend void power(mpbq & a, mpbq const & b, unsigned k);

    /**
       \brief Return the magnitude of a = b/2^k.
       It is defined as:
        a == 0 -> 0
        a >  0 -> log2(b) - k          Note that  2^{log2(b) - k}       <= a <=  2^{log2(b) - k + 1}
        a <  0 -> mlog2(b) - k + 1     Note that -2^{mlog2(b) - k + 1}  <= a <= -2^{mlog2(b) - k}

        Remark: mlog2(b) = log2(-b)

        Examples:
        
        5/2^3     log2(5)  - 3      = -1
        21/2^2    log2(21) - 2      =  2
        -3/2^4    log2(3)  - 4  + 1 = -2
    */
    int magnitude_lb() const;

    /**
       \brief Similar to magnitude_lb

        a == 0 -> 0
        a >  0 -> log2(b) - k + 1           a <=  2^{log2(b) - k + 1}
        a <  0 -> mlog2(b) - k              a <= -2^{mlog2(b) - k}
    */
    int magnitude_ub() const;

    // a <- a*2
    friend void mul2(mpbq & a);
    // a <- a*2^k
    friend void mul2k(mpbq & a, unsigned k);
    // a <- b * 2^k
    friend void mul2k(mpbq & a, mpbq const & b, unsigned k) { a = b; mul2k(a, k); }
    
    // a <- a/2
    friend void div2(mpbq & a) { bool old_k_zero = (a.m_k == 0); a.m_k++; if (old_k_zero) a.normalize(); }
    // a <- a/2^k
    friend void div2k(mpbq & a, unsigned k) { bool old_k_zero = (a.m_k == 0); a.m_k += k; if (old_k_zero) a.normalize(); }
    // a <- b / 2^k
    friend void div2k(mpbq & a, mpbq const & b, unsigned k) { a = b; div2k(a, k); }

    /**
       \brief Return true if b^{1/n} is a binary rational, and store the result in a.
       Otherwise, return false and return an lower bound based on the integer root of the 
       numerator and denominator/n
    */
    friend bool root_lower(mpbq & a, mpbq const & b, unsigned n);
    friend bool root_upper(mpbq & a, mpbq const & b, unsigned n);

    /**
       \brief Given a rational q which cannot be represented as a binary rational,
       and an interval (l, u) s.t. l < q < u. This method stores in u, a u' s.t.
       q < u' < u.
       In the refinement process, the lower bound l may be also refined to l' 
       s.t. l < l' < q
    */
    friend void refine_upper(mpq const & q, mpbq & l, mpbq & u);
    /**
       \brief Similar to refine_upper.
    */
    friend void refine_lower(mpq const & q, mpbq & l, mpbq & u);

    /**
       \brief Return true iff a < 1/2^k
    */
    friend bool lt_1div2k(mpbq const & a, unsigned k);

    friend std::ostream & operator<<(std::ostream & out, mpbq const & v);

    friend void display_decimal(std::ostream & out, mpbq const & a, unsigned prec);

    class decimal {
        mpbq const & m_val;
        unsigned     m_prec;
    public:
        decimal(mpbq const & val, unsigned prec = 10):m_val(val), m_prec(prec) {}
        friend std::ostream & operator<<(std::ostream & out, decimal const & d) { display_decimal(out, d.m_val, d.m_prec); return out; }
    };
};

template<>
class numeric_traits<mpbq> {
public:
    static bool is_zero(mpbq const &  v) { return v.is_zero(); }
    static bool is_pos(mpbq const & v) { return v.is_pos(); }
    static bool is_neg(mpbq const & v) { return v.is_neg(); }
    static void set_rounding(bool plus_inf) {}
    static void neg(mpbq & v) { v.neg(); }
    static void reset(mpbq & v) { v = 0; }
};

}
