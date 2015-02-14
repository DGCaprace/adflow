   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of bcturbsymm in forward (tangent) mode (with options i4 dr8 r8):
   !   variations   of useful results: *bmtk1 *bmtk2 *bmti1 *bmti2
   !                *bmtj1 *bmtj2
   !   with respect to varying inputs: *bmtk1 *bmtk2 *bmti1 *bmti2
   !                *bmtj1 *bmtj2
   !   Plus diff mem management of: bmtk1:in bmtk2:in bmti1:in bmti2:in
   !                bmtj1:in bmtj2:in bcdata:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          bcTurbSymm.F90                                  *
   !      * Author:        Georgi Kalitzin, Edwin van der Weide            *
   !      * Starting date: 06-11-2003                                      *
   !      * Last modified: 06-12-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE BCTURBSYMM_D(nn)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * bcTurbSymm applies the implicit treatment of the symmetry      *
   !      * boundary condition (or inviscid wall) to subface nn. As the    *
   !      * symmetry boundary condition is independent of the turbulence   *
   !      * model, this routine is valid for all models. It is assumed     *
   !      * that the pointers in blockPointers are already set to the      *
   !      * correct block on the correct grid level.                       *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BLOCKPOINTERS_D
   USE BCTYPES
   USE FLOWVARREFSTATE
   IMPLICIT NONE
   !
   !      Subroutine arguments.
   !
   INTEGER(kind=inttype), INTENT(IN) :: nn
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: i, j, l
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Loop over the faces of the subfaces and set the values of bmt
   ! for an implicit treatment. For a symmetry face this means
   ! that the halo value is set to the internal value.
   DO j=bcdata(nn)%jcbeg,bcdata(nn)%jcend
   DO i=bcdata(nn)%icbeg,bcdata(nn)%icend
   DO l=nt1,nt2
   SELECT CASE  (bcfaceid(nn)) 
   CASE (imin) 
   bmti1d(i, j, l, l) = 0.0_8
   bmti1(i, j, l, l) = -one
   CASE (imax) 
   bmti2d(i, j, l, l) = 0.0_8
   bmti2(i, j, l, l) = -one
   CASE (jmin) 
   bmtj1d(i, j, l, l) = 0.0_8
   bmtj1(i, j, l, l) = -one
   CASE (jmax) 
   bmtj2d(i, j, l, l) = 0.0_8
   bmtj2(i, j, l, l) = -one
   CASE (kmin) 
   bmtk1d(i, j, l, l) = 0.0_8
   bmtk1(i, j, l, l) = -one
   CASE (kmax) 
   bmtk2d(i, j, l, l) = 0.0_8
   bmtk2(i, j, l, l) = -one
   END SELECT
   END DO
   END DO
   END DO
   END SUBROUTINE BCTURBSYMM_D