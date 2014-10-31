   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          paramTurb.f90                                  *
   !      * Author:        Edwin van der Weide, Georgi Kalitzin            *
   !      * Starting date: 06-11-2003                                      *
   !      * Last modified: 03-22-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   MODULE PARAMTURB_B
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Module that contains the constants for the turbulence models   *
   !      * as well as some global variables/parameters for the turbulent  *
   !      * routines.                                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   USE PRECISION
   IMPLICIT NONE
   SAVE 
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Spalart-Allmaras constants.                                    *
   !      *                                                                *
   !      ******************************************************************
   !
   REAL(kind=realtype), PARAMETER :: rsak=0.41_realType
   REAL(kind=realtype), PARAMETER :: rsacb1=0.1355_realType
   REAL(kind=realtype), PARAMETER :: rsacb2=0.622_realType
   REAL(kind=realtype), PARAMETER :: rsacb3=0.66666666667_realType
   REAL(kind=realtype), PARAMETER :: rsacv1=7.1_realType
   REAL(kind=realtype), PARAMETER :: rsacw1=rsacb1/rsak**2+(1.+rsacb2)/&
   &   rsacb3
   REAL(kind=realtype), PARAMETER :: rsacw2=0.3_realType
   REAL(kind=realtype), PARAMETER :: rsacw3=2.0_realType
   REAL(kind=realtype), PARAMETER :: rsact1=1.0_realType
   REAL(kind=realtype), PARAMETER :: rsact2=2.0_realType
   REAL(kind=realtype), PARAMETER :: rsact3=1.2_realType
   REAL(kind=realtype), PARAMETER :: rsact4=0.5_realType
   !
   !      ******************************************************************
   !      *                                                                *
   !      * K-omega constants.                                             *
   !      *                                                                *
   !      ******************************************************************
   !
   REAL(kind=realtype), PARAMETER :: rkwk=0.41_realType
   REAL(kind=realtype), PARAMETER :: rkwsigk1=0.5_realType
   REAL(kind=realtype), PARAMETER :: rkwsigw1=0.5_realType
   REAL(kind=realtype), PARAMETER :: rkwsigd1=0.5_realType
   REAL(kind=realtype), PARAMETER :: rkwbeta1=0.0750_realType
   REAL(kind=realtype), PARAMETER :: rkwbetas=0.09_realType
   !
   !      ******************************************************************
   !      *                                                                *
   !      * K-omega SST constants.                                         *
   !      *                                                                *
   !      ******************************************************************
   !
   REAL(kind=realtype), PARAMETER :: rsstk=0.41_realType
   REAL(kind=realtype), PARAMETER :: rssta1=0.31_realType
   REAL(kind=realtype), PARAMETER :: rsstbetas=0.09_realType
   REAL(kind=realtype), PARAMETER :: rsstsigk1=0.85_realType
   REAL(kind=realtype), PARAMETER :: rsstsigw1=0.5_realType
   REAL(kind=realtype), PARAMETER :: rsstbeta1=0.0750_realType
   REAL(kind=realtype), PARAMETER :: rsstsigk2=1.0_realType
   REAL(kind=realtype), PARAMETER :: rsstsigw2=0.856_realType
   REAL(kind=realtype), PARAMETER :: rsstbeta2=0.0828_realType
   !
   !      ******************************************************************
   !      *                                                                *
   !      * K-tau constants.                                               *
   !      *                                                                *
   !      ******************************************************************
   !
   REAL(kind=realtype), PARAMETER :: rktk=0.41_realType
   REAL(kind=realtype), PARAMETER :: rktsigk1=0.5_realType
   REAL(kind=realtype), PARAMETER :: rktsigt1=0.5_realType
   REAL(kind=realtype), PARAMETER :: rktsigd1=0.5_realType
   REAL(kind=realtype), PARAMETER :: rktbeta1=0.0750_realType
   REAL(kind=realtype), PARAMETER :: rktbetas=0.09_realType
   !
   !      ******************************************************************
   !      *                                                                *
   !      * V2-f constants.                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   REAL(kind=realtype), PARAMETER :: rvfc1=1.4_realType
   REAL(kind=realtype), PARAMETER :: rvfc2=0.3_realType
   REAL(kind=realtype), PARAMETER :: rvfbeta=1.9_realType
   REAL(kind=realtype), PARAMETER :: rvfsigk1=1.0_realType
   REAL(kind=realtype), PARAMETER :: rvfsige1=0.7692307692_realType
   REAL(kind=realtype), PARAMETER :: rvfsigv1=1.00_realType
   REAL(kind=realtype), PARAMETER :: rvfcn=70.0_realType
   REAL(kind=realtype), PARAMETER :: rvfn1cmu=0.190_realType
   REAL(kind=realtype), PARAMETER :: rvfn1a=1.300_realType
   REAL(kind=realtype), PARAMETER :: rvfn1b=0.250_realType
   REAL(kind=realtype), PARAMETER :: rvfn1cl=0.300_realType
   REAL(kind=realtype), PARAMETER :: rvfn6cmu=0.220_realType
   REAL(kind=realtype), PARAMETER :: rvfn6a=1.400_realType
   REAL(kind=realtype), PARAMETER :: rvfn6b=0.045_realType
   REAL(kind=realtype), PARAMETER :: rvfn6cl=0.230_realType
   REAL(kind=realtype) :: rvflimitk, rvflimite, rvfcl
   REAL(kind=realtype) :: rvfcmu
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Variables to store the parameters for the wall functions fits. *
   !      * As these variables depend on the turbulence model they are set *
   !      * during runtime. Allocatables are used, because the number of   *
   !      * fits could be different for the different models.              *
   !      * The curve is divided in a number of intervals and is           *
   !      * constructed such that both the function and the derivatives    *
   !      * are continuous. Consequently cubic polynomials are used.       *
   !      *                                                                *
   !      ******************************************************************
   !
   ! nFit:               Number of intervals of the curve.
   ! ypT(0:nFit):        y+ values at the interval boundaries.
   ! reT(0:nFit):        Reynolds number at the interval
   !                     boundaries, where the Reynolds number is
   !                     defined with the local velocity and the
   !                     wall distance.
   ! up0(nFit):          Coefficient 0 in the fit for the
   !                     nondimensional tangential velocity as a
   !                     function of the Reynolds number.
   ! up1(nFit):          Idem for coefficient 1.
   ! up2(nFit):          Idem for coefficient 2.
   ! up3(nFit):          Idem for coefficient 3.
   ! tup0(nFit,nt1:nt2): Coefficient 0 in the fit for the
   !                     nondimensional turbulence variables as a
   !                     function of y+.
   ! tup1(nFit,nt1:nt2): Idem for coefficient 1.
   ! tup2(nFit,nt1:nt2): Idem for coefficient 2.
   ! tup3(nFit,nt1:nt2): Idem for coefficient 3.
   ! tuLogFit(nt1:nt2):  Whether or not the logarithm of the variable
   !                     has been fitted.
   INTEGER(kind=inttype) :: nfit
   REAL(kind=realtype), DIMENSION(:), ALLOCATABLE :: ypt, ret
   REAL(kind=realtype), DIMENSION(:), ALLOCATABLE :: up0, up1
   REAL(kind=realtype), DIMENSION(:), ALLOCATABLE :: up2, up3
   REAL(kind=realtype), DIMENSION(:, :), ALLOCATABLE :: tup0, tup1
   REAL(kind=realtype), DIMENSION(:, :), ALLOCATABLE :: tup2, tup3
   LOGICAL, DIMENSION(:), ALLOCATABLE :: tulogfit
   END MODULE PARAMTURB_B
