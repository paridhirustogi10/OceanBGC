! This code comes from GOLD/config_src/coupled_driver here to be shared.
! But, the interfaces need a little change to work properly with generic tracers.
! The lower bounds of arrays should be specified in the arguments otherwise it core with "out of bound" message.
! For this reason I names the module FMS_coupler_util to distinguish it from GOLD coupler_util
! 
module FMS_coupler_util

!   This code provides a couple of interfaces to allow more transparent and
! robust extraction of the various fields in the coupler types.
use mpp_mod,           only : mpp_error, FATAL, WARNING
use coupler_types_mod, only : coupler_2d_bc_type, ind_flux, ind_deltap, ind_kw, ind_kw_asym, ind_out1, ind_out2 ! # bgr_prustogi #Xiaohui
use coupler_types_mod, only : ind_alpha, ind_csurf, ind_sc_no

implicit none ; private

public :: extract_coupler_values, set_coupler_values

contains

subroutine extract_coupler_values(BC_struc, BC_index, BC_element, array_out, ilb, jlb, &
                                  is, ie, js, je, conversion)
  real, dimension(ilb:,jlb:),intent(out) :: array_out
  integer,                   intent(in)  :: ilb, jlb !nnz: I have to pass these otherwise out os bound array reference for array_out inside extract_coupler_values. Why? How come GOLD is OK? 
  type(coupler_2d_bc_type),  intent(in)  :: BC_struc
  integer,                   intent(in)  :: BC_index, BC_element
  integer,        optional,  intent(in)  :: is, ie, js, je
  real,           optional,  intent(in)  :: conversion
! Arguments: BC_struc - The type from which the data is being extracted.
!  (in)      BC_index - The boundary condition number being extracted.
!  (in)      BC_element - The element of the boundary condition being extracted.
!            This could be ind_csurf, ind_alpha, ind_sc_no, ind_flux, ind_deltap,
!            ind_kw or ind_deposition.
!  (out)     array_out - The array being filled with the input values.
!  (in, opt) is, ie, js, je - The i- and j- limits of array_out to be filled.
!            These must match the size of the corresponding value array or an
!            error message is issued.
!  (in, opt) conversion - A number that every element is multiplied by, to
!                         permit sign convention or unit conversion.

  real, pointer, dimension(:,:) :: Array_in
  real :: conv
  integer :: i, j, is0, ie0, js0, je0, i_offset, j_offset

  if ((BC_element /= ind_flux) .and. (BC_element /= ind_alpha) .and. &
      (BC_element /= ind_csurf) .and. (BC_element /= ind_sc_no) .and. &
      (BC_element /= ind_deltap) .and. (BC_element /= ind_kw) .and. &
      (BC_element /= ind_kw_asym) .and. & ! Xiaohui
      (BC_element /= ind_out1) .and. (BC_element /= ind_out2)) then ! #bgr_prustogi
    call mpp_error(FATAL,"extract_coupler_values: Unrecognized BC_element.")
  endif

  ! These error messages should be made more explicit.
!  if (.not.associated(BC_struc%bc(BC_index))) &
  if (.not.associated(BC_struc%bc)) &
    call mpp_error(FATAL,"extract_coupler_values: " // &
       "The requested boundary condition is not associated.")
!  if (.not.associated(BC_struc%bc(BC_index)%field(BC_element))) &
  if (.not.associated(BC_struc%bc(BC_index)%field)) &
    call mpp_error(FATAL,"extract_coupler_values: " // &
       "The requested boundary condition element is not associated.")
  if (.not.associated(BC_struc%bc(BC_index)%field(BC_element)%values)) &
    call mpp_error(FATAL,"extract_coupler_values: " // &
       "The requested boundary condition value array is not associated.")

  Array_in => BC_struc%bc(BC_index)%field(BC_element)%values
  
  if (present(is)) then ; is0 = is ; else ; is0 = LBOUND(array_out,1) ; endif
  if (present(ie)) then ; ie0 = ie ; else ; ie0 = UBOUND(array_out,1) ; endif
  if (present(js)) then ; js0 = js ; else ; js0 = LBOUND(array_out,2) ; endif
  if (present(je)) then ; je0 = je ; else ; je0 = UBOUND(array_out,2) ; endif

  conv = 1.0 ; if (present(conversion)) conv = conversion

  if (size(Array_in,1) /= ie0 - is0 + 1) &
    call mpp_error(FATAL,"extract_coupler_values: Mismatch in i-size " // &
                   "between BC array and output array or computational domain.")
  if (size(Array_in,2) /= je0 - js0 + 1) &
    call mpp_error(FATAL,"extract_coupler_values: Mismatch in i-size " // &
                   "between BC array and output array or computational domain.")
  i_offset = lbound(Array_in,1) - is0
  j_offset = lbound(Array_in,2) - js0
  do j=js0,je0 ; do i=is0,ie0
    array_out(i,j) = conv * Array_in(i+i_offset,j+j_offset)
  enddo ; enddo

end subroutine extract_coupler_values

subroutine set_coupler_values(array_in, BC_struc, BC_index, BC_element, ilb, jlb,&
                              is, ie, js, je, conversion)
  real, dimension(ilb:,jlb:), intent(in)  :: array_in
  integer,                  intent(in)    :: ilb, jlb !nnz: I have to pass these otherwise out of bound array reference for array_in. Why? How come GOLD is OK?   
  type(coupler_2d_bc_type), intent(inout) :: BC_struc
  integer,                  intent(in)    :: BC_index, BC_element
  integer,        optional, intent(in)    :: is, ie, js, je
  real,           optional, intent(in)    :: conversion
! Arguments: array_in - The array containing the values to load into the BC.
!  (out)     BC_struc - The type into which the data is being loaded.
!  (in)      BC_index - The boundary condition number being extracted.
!  (in)      BC_element - The element of the boundary condition being extracted.
!            This could be ind_csurf, ind_alpha, ind_sc_no, ind_flux, ind_deltap,
!            ind_kw or ind_deposition.
!  (in, opt) is, ie, js, je - The i- and j- limits of array_out to be filled.
!            These must match the size of the corresponding value array or an
!            error message is issued.
!  (in, opt) conversion - A number that every element is multiplied by, to
!                         permit sign convention or unit conversion.

  real, pointer, dimension(:,:) :: Array_out
  real :: conv
  integer :: i, j, is0, ie0, js0, je0, i_offset, j_offset

  if ((BC_element /= ind_flux) .and. (BC_element /= ind_alpha) .and. &
      (BC_element /= ind_csurf) .and. (BC_element /= ind_sc_no) .and. &
      (BC_element /= ind_deltap) .and. (BC_element /= ind_kw) .and. &
      (BC_element /= ind_kw_asym) .and. & ! Xiaohui
      (BC_element /= ind_out1) .and. (BC_element /= ind_out2)) then ! #bgr_prustogi
    call mpp_error(FATAL,"extract_coupler_values: Unrecognized BC_element.")
  endif

  ! These error messages should be made more explicit.
!  if (.not.associated(BC_struc%bc(BC_index))) &
  if (.not.associated(BC_struc%bc)) &
    call mpp_error(FATAL,"set_coupler_values: " // &
       "The requested boundary condition is not associated.")
!  if (.not.associated(BC_struc%bc(BC_index)%field(BC_element))) &
  if (.not.associated(BC_struc%bc(BC_index)%field)) &
    call mpp_error(FATAL,"set_coupler_values: " // &
       "The requested boundary condition element is not associated.")
  if (.not.associated(BC_struc%bc(BC_index)%field(BC_element)%values)) &
    call mpp_error(FATAL,"set_coupler_values: " // &
       "The requested boundary condition value array is not associated.")

  Array_out => BC_struc%bc(BC_index)%field(BC_element)%values
  
  if (present(is)) then ; is0 = is ; else ; is0 = LBOUND(array_in,1) ; endif
  if (present(ie)) then ; ie0 = ie ; else ; ie0 = UBOUND(array_in,1) ; endif
  if (present(js)) then ; js0 = js ; else ; js0 = LBOUND(array_in,2) ; endif
  if (present(je)) then ; je0 = je ; else ; je0 = UBOUND(array_in,2) ; endif

  conv = 1.0 ; if (present(conversion)) conv = conversion

  if (size(Array_out,1) /= ie0 - is0 + 1) &
    call mpp_error(FATAL,"extract_coupler_values: Mismatch in i-size " // &
                   "between BC array and input array or computational domain.")
  if (size(Array_out,2) /= je0 - js0 + 1) &
    call mpp_error(FATAL,"extract_coupler_values: Mismatch in i-size " // &
                   "between BC array and input array or computational domain.")
  i_offset = lbound(Array_out,1) - is0
  j_offset = lbound(Array_out,2) - js0
  do j=js0,je0 ; do i=is0,ie0
    Array_out(i+i_offset,j+j_offset) = conv * array_in(i,j)
  enddo ; enddo

end subroutine set_coupler_values

end module FMS_coupler_util
