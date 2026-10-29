package com.juan.api_delivery.produto;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VinhoRepository extends JpaRepository<Vinho, Long> {
}
