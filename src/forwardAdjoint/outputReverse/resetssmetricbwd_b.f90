   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of resetssmetricbwd in reverse (adjoint) mode (with options i4 dr8 r8 noISIZE):
   !   gradient     of useful results: *si *sj *sk ss
   !   with respect to varying inputs: *si *sj *sk ss
   !   Plus diff mem management of: si:in sj:in sk:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          resetssMetricBwd.f90                            *
   !      * Author:        Peter Zhoujie Lyu                               *
   !      * Starting date: 11-03-2014                                      *
   !      * Last modified: 11-03-2014                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE RESETSSMETRICBWD_B(nn, ss, ssb)
   USE BCTYPES
   USE BLOCKPOINTERS_B
   USE FLOWVARREFSTATE
   IMPLICIT NONE
   !
   !      Subroutine arguments.
   !
   INTEGER(kind=inttype), INTENT(IN) :: nn
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim, 3) :: ss
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim, 3) :: ssb
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Determine the face id on which the subface is located and set
   ! the pointers accordinly.
   SELECT CASE  (bcfaceid(nn)) 
   CASE (imin) 
   ssb(1:je, 1:ke, :) = ssb(1:je, 1:ke, :) + sib(1, 1:je, 1:ke, :)
   sib(1, 1:je, 1:ke, :) = 0.0_8
   CASE (imax) 
   ssb(1:je, 1:ke, :) = ssb(1:je, 1:ke, :) + sib(il, 1:je, 1:ke, :)
   sib(il, 1:je, 1:ke, :) = 0.0_8
   CASE (jmin) 
   ssb(1:ie, 1:ke, :) = ssb(1:ie, 1:ke, :) + sjb(1:ie, 1, 1:ke, :)
   sjb(1:ie, 1, 1:ke, :) = 0.0_8
   CASE (jmax) 
   ssb(1:ie, 1:ke, :) = ssb(1:ie, 1:ke, :) + sjb(1:ie, jl, 1:ke, :)
   sjb(1:ie, jl, 1:ke, :) = 0.0_8
   CASE (kmin) 
   ssb(1:ie, 1:je, :) = ssb(1:ie, 1:je, :) + skb(1:ie, 1:je, 1, :)
   skb(1:ie, 1:je, 1, :) = 0.0_8
   CASE (kmax) 
   ssb(1:ie, 1:je, :) = ssb(1:ie, 1:je, :) + skb(1:ie, 1:je, kl, :)
   skb(1:ie, 1:je, kl, :) = 0.0_8
   END SELECT
   END SUBROUTINE RESETSSMETRICBWD_B
